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
