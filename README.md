# FluxKey
A decentralized key management solution built on Stacks blockchain using Clarity.

## Overview
FluxKey allows users to securely store and manage access keys on the blockchain. The system enables:
- Key storage with encryption
- Key sharing between users
- Access revocation
- Key expiration
- Ownership transfer
- Access history tracking

## Features
- Store encrypted keys tied to user principal
- Share access with other principals
- Revoke previously granted access
- Set and check key expiration
- Transfer key ownership
- Track access history
- Add and update key metadata
- View comprehensive key information

## Usage
### Storing a Key
```clarity
(contract-call? .flux-key store-key "encrypted-data" expiration-height "metadata")
```

### Transferring Ownership
```clarity
(contract-call? .flux-key transfer-ownership key-id new-owner-principal)
```

### Managing Access
```clarity
(contract-call? .flux-key grant-access key-id user-principal)
(contract-call? .flux-key revoke-access key-id user-principal)
```
