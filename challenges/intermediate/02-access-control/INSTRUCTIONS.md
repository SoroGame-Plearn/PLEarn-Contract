# Challenge: Access Control

## Difficulty: Intermediate
## Time Estimate: 60–90 minutes

## Objective
Implement a role-based access control contract.

## Requirements
- `initialize(admin: Address)`
- `grant_role(admin: Address, user: Address, role: Symbol)`
- `revoke_role(admin: Address, user: Address, role: Symbol)`
- `has_role(user: Address, role: Symbol) -> bool`
- `restricted_action(caller: Address)` — only callable by users with `"operator"` role

## Expected Behavior
- Only admin can grant/revoke roles
- `restricted_action` panics if caller lacks the required role
- Roles persist across calls

## Hints
- Use `soroban_sdk::Symbol` for role names
- Store roles as `Map<Address, Vec<Symbol>>`
