# GraceVault - Smart Contract README

## Overview

**GraceVault** is a Clarity smart contract that implements a "dead man's switch" vault mechanism on the Stacks blockchain. It allows users to lock funds with designated beneficiaries, where the funds can only be claimed if the original owner fails to "ping" the vault within a specified timeout period.

## Features

- **Vault Creation**: Create secure vaults with configurable unlock times and beneficiaries
- **Ping Mechanism**: Owners can ping vaults to reset the claim timer and prevent beneficiary access
- **Beneficiary Claims**: Beneficiaries can claim locked funds after unlock conditions are met
- **Vault Cancellation**: Owners can cancel vaults before expiration to retrieve funds
- **Admin Management**: Contract administrator controls with ability to transfer admin privileges
- **Error Handling**: Comprehensive error codes for transaction validation

## How It Works

### Vault Lifecycle

1. **Creation**: Owner creates a vault, specifying:
   - Beneficiary principal address
   - Lock amount (in micro STX or sBTC units)
   - Unlock time (block height)

2. **Active State**: Owner periodically pings the vault to extend the claim period and prove they're still active

3. **Claim Condition**: Beneficiary can claim funds when:
   - Current block height ≥ unlock time
   - Current block height ≥ (last ping + 100 blocks timeout)
   - Vault hasn't already been claimed

4. **Cancellation**: Owner can cancel at any time before claim to retrieve funds

## Contract Functions

### Public Functions

#### `create-vault (beneficiary, amount, unlock-time)`
Creates a new vault with specified parameters.
- **Parameters**:
  - `beneficiary`: Principal address of beneficiary
  - `amount`: Amount to lock
  - `unlock-time`: Block height after which claim is allowed
- **Returns**: `vault-id` on success

#### `ping (vault-id)`
Updates the last-ping timestamp to reset the claim timeout.
- **Parameters**: `vault-id` - ID of vault to ping
- **Returns**: `true` on success
- **Requirements**: Must be vault owner; 100 blocks must have passed since last ping

#### `claim (vault-id)`
Allows beneficiary to claim locked funds.
- **Parameters**: `vault-id` - ID of vault to claim
- **Returns**: `true` on success
- **Requirements**: Must be beneficiary; unlock time and timeout conditions must be met

#### `cancel-vault (vault-id)`
Allows owner to cancel vault and retrieve funds.
- **Parameters**: `vault-id` - ID of vault to cancel
- **Returns**: `true` on success
- **Requirements**: Must be vault owner; vault not already claimed

#### `set-admin (new-admin)`
Transfers admin privileges to a new principal.
- **Parameters**: `new-admin` - Principal address of new admin
- **Returns**: New admin address on success
- **Requirements**: Must be current admin

### Read-Only Functions

#### `get-vault (vault-id)`
Retrieves vault data.
- **Parameters**: `vault-id` - ID of vault
- **Returns**: Vault structure or None if not found

## Vault Structure

```clarity
{
  owner: principal,           ;; Vault creator
  beneficiary: principal,     ;; Authorized claimer
  amount: uint,              ;; Locked amount
  unlock-time: uint,         ;; Block height threshold
  last-ping: uint,           ;; Last ping block height
  claimed: bool              ;; Claim status
}
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 100 | ERR-UNAUTHORIZED | Action not authorized |
| 101 | ERR-VAULT-NOT-FOUND | Vault does not exist |
| 102 | ERR-VAULT-LOCKED | Vault is currently locked |
| 103 | ERR-VAULT-EXPIRED | Vault has already been claimed |
| 104 | ERR-NOT-BENEFICIARY | Caller is not the beneficiary |
| 105 | ERR-NOT-OWNER | Caller is not the vault owner |
| 106 | ERR-PING-TOO-EARLY | Insufficient blocks since last ping |

## Usage Example

```clarity
;; Create a vault that unlocks at block 1000 with 1 million micro-STX
(create-vault 'SP1234... u1000000 u1000)
;; Returns: (ok u1)

;; Owner pings vault to extend timeout
(ping u1)
;; Returns: (ok true)

;; Beneficiary claims after conditions are met
(claim u1)
;; Returns: (ok true)
```

## Future Enhancements

- **Token Transfers**: Integrate STX/sBTC transfer on claim
- **Multiple Beneficiaries**: Support shared beneficiaries
- **Tiered Unlocks**: Partial claims at different intervals
- **Recovery Fund**: Admin withdraw mechanism for unclaimed vaults



## Support

For issues or questions, please open an issue in the repository.
