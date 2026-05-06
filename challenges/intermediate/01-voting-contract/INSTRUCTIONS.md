# Challenge: Voting Contract

## Difficulty: Intermediate

## Objective
Build an on-chain voting contract where users vote on proposals.

## Requirements
- `create_proposal(title: String) -> u32` — returns proposal ID
- `vote(voter: Address, proposal_id: u32)` — cast a vote
- `get_votes(proposal_id: u32) -> u32` — return vote count
- Each address can only vote once per proposal

## Expected Behavior
- Duplicate votes are rejected
- Vote counts increment correctly
- Non-existent proposal IDs panic

## Hints
- Use nested storage: proposal_id → list of voters
- Use `soroban_sdk::Vec` or `Map` to track voters per proposal
