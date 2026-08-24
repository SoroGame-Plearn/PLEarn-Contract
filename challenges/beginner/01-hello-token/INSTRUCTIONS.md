# Challenge: Hello Token

## Difficulty: Beginner
## Time Estimate: 20–30 minutes

## Objective
Deploy a simple Soroban token contract that can mint and return a balance.

## Requirements
- Implement `initialize(admin: Address)`
- Implement `mint(to: Address, amount: i128)` — admin only
- Implement `balance(account: Address) -> i128`

## Expected Behavior
- Only the admin can mint tokens
- `balance()` returns the correct amount after minting
- Minting to a new address starts from 0

## Hints
- Use `soroban_sdk::Map` to store balances
- Use `Address::require_auth()` to enforce admin-only access

## Test Coverage
`src/lib.rs` includes 15 unit tests covering the happy path plus edge
cases and security scenarios:
- Re-initialization (same admin and a different admin) is rejected
- Minting to a special, non-user address (the contract's own address)
- Negative mint amounts are rejected, including against an existing balance
- Minting `i128::MAX` and minting past it (overflow must panic, not wrap)
- A non-admin authorized caller cannot mint, and mint fails with no
  authorization mocked at all
- `balance()` on multiple never-touched accounts returns 0
- A parametrized sweep of mint amounts (including 0)
- Event emission on `mint`
