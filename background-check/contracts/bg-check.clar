;; Criminal Background Verification Contract
;; Self-Sovereign Identity System on Stacks Blockchain

;; Contract Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-UNAUTHORIZED (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-INPUT (err u104))
(define-constant ERR-EXPIRED (err u105))

;; Data Variables
(define-data-var contract-active bool true)
(define-data-var verification-fee uint u1000000) ;; 1 STX in microSTX

;; Data Maps
;; User identity records
(define-map user-identities
  { user: principal }
  {
    identity-hash: (buff 32),
    created-at: uint,
    updated-at: uint,
    verification-level: uint,
    is-active: bool
  }
)

;; Background check records
(define-map background-checks
  { user: principal, check-id: uint }
  {
    status: (string-ascii 20),
    verified-by: principal,
    verification-date: uint,
    expiry-date: uint,
    criminal-record: bool,
    risk-level: uint,
    metadata-hash: (buff 32)
  }
)

;; Authorized verifiers
(define-map authorized-verifiers
  { verifier: principal }
  {
    name: (string-ascii 50),
    license-id: (string-ascii 30),
    authorized-at: uint,
    is-active: bool
  }
)

;; User permissions for data access
(define-map access-permissions
  { user: principal, verifier: principal }
  {
    granted-at: uint,
    expires-at: uint,
    access-level: uint,
    is-active: bool
  }
)

;; Check ID counter
(define-data-var next-check-id uint u1)

;; Read-only functions

;; Get user identity
(define-read-only (get-user-identity (user principal))
  (map-get? user-identities { user: user })
)

;; Get background check
(define-read-only (get-background-check (user principal) (check-id uint))
  (map-get? background-checks { user: user, check-id: check-id })
)

;; Check if verifier is authorized
(define-read-only (is-authorized-verifier (verifier principal))
  (match (map-get? authorized-verifiers { verifier: verifier })
    verifier-data (get is-active verifier-data)
    false
  )
)

;; Check access permission
(define-read-only (has-access-permission (user principal) (verifier principal))
  (match (map-get? access-permissions { user: user, verifier: verifier })
    permission-data 
    (and 
      (get is-active permission-data)
      (< block-height (get expires-at permission-data))
    )
    false
  )
)

;; Get verification fee
(define-read-only (get-verification-fee)
  (var-get verification-fee)
)

;; Public functions

;; Register user identity (self-sovereign)
(define-public (register-identity (identity-hash (buff 32)))
  (let ((user tx-sender))
    (asserts! (var-get contract-active) (err u106))
    (asserts! (is-none (map-get? user-identities { user: user })) ERR-ALREADY-EXISTS)
    (asserts! (> (len identity-hash) u0) ERR-INVALID-INPUT)
    
    (map-set user-identities
      { user: user }
      {
        identity-hash: identity-hash,
        created-at: block-height,
        updated-at: block-height,
        verification-level: u1,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Update user identity
(define-public (update-identity (identity-hash (buff 32)))
  (let ((user tx-sender))
    (asserts! (var-get contract-active) (err u106))
    (asserts! (is-some (map-get? user-identities { user: user })) ERR-NOT-FOUND)
    (asserts! (> (len identity-hash) u0) ERR-INVALID-INPUT)
    
    (match (map-get? user-identities { user: user })
      identity-data
      (begin
        (map-set user-identities
          { user: user }
          (merge identity-data {
            identity-hash: identity-hash,
            updated-at: block-height
          })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

;; Grant access permission to verifier
(define-public (grant-access (verifier principal) (duration uint) (access-level uint))
  (let ((user tx-sender))
    (asserts! (var-get contract-active) (err u106))
    (asserts! (is-authorized-verifier verifier) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? user-identities { user: user })) ERR-NOT-FOUND)
    (asserts! (and (>= access-level u1) (<= access-level u3)) ERR-INVALID-INPUT)
    
    (map-set access-permissions
      { user: user, verifier: verifier }
      {
        granted-at: block-height,
        expires-at: (+ block-height duration),
        access-level: access-level,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Revoke access permission
(define-public (revoke-access (verifier principal))
  (let ((user tx-sender))
    (asserts! (var-get contract-active) (err u106))
    (asserts! (is-some (map-get? access-permissions { user: user, verifier: verifier })) ERR-NOT-FOUND)
    
    (match (map-get? access-permissions { user: user, verifier: verifier })
      permission-data
      (begin
        (map-set access-permissions
          { user: user, verifier: verifier }
          (merge permission-data { is-active: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

;; Conduct background check (by authorized verifier)
(define-public (conduct-background-check 
  (user principal) 
  (criminal-record bool) 
  (risk-level uint) 
  (expiry-blocks uint)
  (metadata-hash (buff 32)))
  (let (
    (verifier tx-sender)
    (check-id (var-get next-check-id))
  )
    (asserts! (var-get contract-active) (err u106))
    (asserts! (is-authorized-verifier verifier) ERR-UNAUTHORIZED)
    (asserts! (has-access-permission user verifier) ERR-UNAUTHORIZED)
    (asserts! (is-some (map-get? user-identities { user: user })) ERR-NOT-FOUND)
    (asserts! (and (>= risk-level u0) (<= risk-level u5)) ERR-INVALID-INPUT)
    (asserts! (> expiry-blocks u0) ERR-INVALID-INPUT)
    
    ;; Store background check result
    (map-set background-checks
      { user: user, check-id: check-id }
      {
        status: "COMPLETED",
        verified-by: verifier,
        verification-date: block-height,
        expiry-date: (+ block-height expiry-blocks),
        criminal-record: criminal-record,
        risk-level: risk-level,
        metadata-hash: metadata-hash
      }
    )
    
    ;; Increment check ID counter
    (var-set next-check-id (+ check-id u1))
    
    (ok check-id)
  )
)

;; Verify background check status (public verification)
(define-read-only (verify-background-status (user principal) (check-id uint))
  (match (map-get? background-checks { user: user, check-id: check-id })
    check-data
    (if (< block-height (get expiry-date check-data))
      (ok {
        status: (get status check-data),
        verification-date: (get verification-date check-data),
        criminal-record: (get criminal-record check-data),
        risk-level: (get risk-level check-data),
        is-valid: true
      })
      (ok {
        status: "EXPIRED",
        verification-date: (get verification-date check-data),
        criminal-record: false,
        risk-level: u0,
        is-valid: false
      })
    )
    ERR-NOT-FOUND
  )
)

;; Admin functions

;; Add authorized verifier (contract owner only)
(define-public (add-authorized-verifier 
  (verifier principal) 
  (name (string-ascii 50)) 
  (license-id (string-ascii 30)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (var-get contract-active) (err u106))
    (asserts! (is-none (map-get? authorized-verifiers { verifier: verifier })) ERR-ALREADY-EXISTS)
    
    (map-set authorized-verifiers
      { verifier: verifier }
      {
        name: name,
        license-id: license-id,
        authorized-at: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Remove authorized verifier
(define-public (remove-authorized-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (is-some (map-get? authorized-verifiers { verifier: verifier })) ERR-NOT-FOUND)
    
    (match (map-get? authorized-verifiers { verifier: verifier })
      verifier-data
      (begin
        (map-set authorized-verifiers
          { verifier: verifier }
          (merge verifier-data { is-active: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)

;; Set verification fee
(define-public (set-verification-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (var-set verification-fee new-fee)
    (ok true)
  )
)

;; Toggle contract active status
(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Emergency functions

;; Deactivate user identity (emergency only)
(define-public (emergency-deactivate-identity (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (is-some (map-get? user-identities { user: user })) ERR-NOT-FOUND)
    
    (match (map-get? user-identities { user: user })
      identity-data
      (begin
        (map-set user-identities
          { user: user }
          (merge identity-data { is-active: false })
        )
        (ok true)
      )
      ERR-NOT-FOUND
    )
  )
)