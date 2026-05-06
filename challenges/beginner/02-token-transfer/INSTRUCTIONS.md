# Challenge: Token Transfer

## Difficulty: Beginner

## Objective
Extend a token contract to support peer-to-peer transfers.

## Requirements
- Implement `initialize(admin: Address)` and `mint(to: Address, amount: i128)`
- Implement `transfer(from: Address, to: Address, amount: i128)`
- Implement `balance(account: Address) -> i128`

## Expected Behavior
- Balance of `from` decreases by `amount`
- Balance of `to` increases by `amount`
- Transfer fails if `from` has insufficient balance
- Sender must authorize the transfer

## Hints
- Use `Address::require_auth()` on the sender
- Panic with a descriptive message on insufficient funds
