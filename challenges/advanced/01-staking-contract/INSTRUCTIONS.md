# Challenge: Staking Contract

## Difficulty: Advanced
## Time Estimate: 90–120 minutes

## Objective
Build a staking contract where users lock tokens and earn rewards over time.

## Requirements
- `stake(user: Address, amount: i128)` — lock tokens
- `unstake(user: Address) -> i128` — withdraw staked tokens + rewards
- `get_stake(user: Address) -> i128` — view staked amount
- Rewards accrue at a fixed rate per ledger (e.g., 1% per 100 ledgers)

## Expected Behavior
- Users cannot unstake more than they staked
- Rewards are calculated based on ledgers elapsed since staking
- Staking again resets the reward timer

## Hints
- Use `env.ledger().sequence()` to track time
- Store `(amount, start_ledger)` per user
