# Criminal Background Verification Smart Contract

A self-sovereign identity and criminal background verification system built on the Stacks blockchain using Clarity smart contracts.

## Overview

This smart contract enables users to maintain control over their digital identity while allowing authorized verifiers to conduct and store criminal background checks. The system prioritizes privacy, user consent, and data sovereignty while providing a trusted verification mechanism for background screening.

## Features

### 🔐 Self-Sovereign Identity
- Users register and control their own digital identity
- Cryptographic hash-based identity storage
- User-controlled access permissions
- Complete data ownership and control

### 🏛️ Authorized Verification System
- Licensed verifier registration and management
- Multi-level access control (1-3 access levels)
- Time-based permission expiration
- Comprehensive audit trail

### 📋 Background Check Management
- Criminal record verification
- Risk level assessment (0-5 scale)
- Expiring verification certificates
- Metadata hash storage for additional data integrity

### 🛡️ Security & Privacy
- Permission-based data access
- Automatic permission expiration
- Emergency deactivation controls
- Input validation and error handling

## Contract Architecture

### Data Structures

- **User Identities**: Stores user identity hashes and verification levels
- **Background Checks**: Contains verification results with expiration dates
- **Authorized Verifiers**: Registry of licensed verification entities  
- **Access Permissions**: User-granted permissions with time limits

### Access Levels

1. **Level 1**: Basic identity verification
2. **Level 2**: Standard background check access
3. **Level 3**: Comprehensive verification access

### Risk Levels

- **0**: No risk identified
- **1**: Very low risk
- **2**: Low risk
- **3**: Medium risk
- **4**: High risk
- **5**: Very high risk

## Getting Started

### Prerequisites

- Stacks blockchain node access
- Clarity CLI or compatible development environment
- STX tokens for transaction fees

### Deployment

1. Clone the contract code
2. Compile using Clarity CLI:
   ```bash
   clarity-cli check background-check.clar
   ```
3. Deploy to Stacks blockchain:
   ```bash
   stx deploy_contract background-check background-check.clar --testnet
   ```

## Usage Guide

### For Users

#### 1. Register Your Identity
```clarity
(contract-call? .background-check register-identity 0x[your-identity-hash])
```

#### 2. Grant Access to a Verifier
```clarity
(contract-call? .background-check grant-access 
  'SP[verifier-address] 
  u144  ;; Duration in blocks (approx 1 day)
  u2)   ;; Access level
```

#### 3. Revoke Access
```clarity
(contract-call? .background-check revoke-access 'SP[verifier-address])
```

#### 4. Update Your Identity
```clarity
(contract-call? .background-check update-identity 0x[new-identity-hash])
```

### For Verifiers

#### 1. Conduct Background Check
```clarity
(contract-call? .background-check conduct-background-check
  'SP[user-address]
  false  ;; No criminal record
  u1     ;; Low risk level
  u4320  ;; Valid for 30 days
  0x[metadata-hash])
```

### For Public Verification

#### Check Background Status
```clarity
(contract-call? .background-check verify-background-status 
  'SP[user-address] 
  u1) ;; Check ID
```

### For Contract Administrators

#### Add Authorized Verifier
```clarity
(contract-call? .background-check add-authorized-verifier
  'SP[verifier-address]
  "Background Check Corp"
  "LIC123456")
```

## API Reference

### Read-Only Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `get-user-identity` | Retrieve user identity data | `user: principal` |
| `get-background-check` | Get specific background check | `user: principal, check-id: uint` |
| `is-authorized-verifier` | Check verifier authorization | `verifier: principal` |
| `has-access-permission` | Verify access permissions | `user: principal, verifier: principal` |
| `get-verification-fee` | Get current verification fee | None |
| `verify-background-status` | Public verification of check status | `user: principal, check-id: uint` |

### Public Functions

| Function | Description | Access Level |
|----------|-------------|--------------|
| `register-identity` | Register new user identity | User |
| `update-identity` | Update existing identity | User |
| `grant-access` | Grant verifier access | User |
| `revoke-access` | Revoke verifier access | User |
| `conduct-background-check` | Perform background verification | Authorized Verifier |
| `add-authorized-verifier` | Add new verifier | Contract Owner |
| `remove-authorized-verifier` | Remove verifier authorization | Contract Owner |
| `set-verification-fee` | Update verification fee | Contract Owner |
| `toggle-contract-active` | Activate/deactivate contract | Contract Owner |
| `emergency-deactivate-identity` | Emergency user deactivation | Contract Owner |

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-OWNER-ONLY | Function restricted to contract owner |
| u101 | ERR-NOT-FOUND | Requested data not found |
| u102 | ERR-UNAUTHORIZED | Insufficient permissions |
| u103 | ERR-ALREADY-EXISTS | Resource already exists |
| u104 | ERR-INVALID-INPUT | Invalid input parameters |
| u105 | ERR-EXPIRED | Resource has expired |
| u106 | - | Contract is inactive |

## Security Considerations

### Best Practices

1. **Identity Hash Security**: Use strong cryptographic hashes for identity storage
2. **Permission Management**: Regularly review and update access permissions
3. **Verification Timing**: Set appropriate expiration periods for background checks
4. **Access Level Control**: Use minimum required access levels
5. **Regular Audits**: Monitor contract activity and permissions

### Known Limitations

- Background check results are publicly readable once created
- Contract owner has emergency override capabilities
- Identity hashes must be managed securely off-chain
- Block-based timing may vary with network conditions

## Integration Examples

### Web Application Integration

```javascript
// Example using Stacks.js
import { openContractCall } from '@stacks/connect';

const registerIdentity = async (identityHash) => {
  await openContractCall({
    contractAddress: 'SP[CONTRACT-ADDRESS]',
    contractName: 'background-check',
    functionName: 'register-identity',
    functionArgs: [bufferCV(identityHash)],
  });
};
```

### CLI Integration

```bash
# Register identity
stx call_contract_func SP[CONTRACT-ADDRESS] background-check register-identity \
  -e 0x[identity-hash] --testnet

# Grant access
stx call_contract_func SP[CONTRACT-ADDRESS] background-check grant-access \
  -e SP[verifier-address] -e u144 -e u2 --testnet
```

## Testing

### Unit Tests

The contract includes comprehensive test coverage for:
- Identity registration and management
- Permission granting and revocation
- Background check creation and verification
- Access control and authorization
- Error handling and edge cases

### Test Network Deployment

Deploy to Stacks testnet for development and testing:
```bash
stx deploy_contract background-check background-check.clar --testnet
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request
