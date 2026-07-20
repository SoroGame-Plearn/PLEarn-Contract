# Challenge: Multisig Wallet

## Difficulty: Advanced
## Time Estimate: 120–180 minutes

## Objective
Implement a M-of-N multisignature wallet where transactions require approval from multiple signers.

## Requirements
- `initialize(signers: Vec<Address>, threshold: u32)`
- `submit_tx(proposer: Address, to: Address, amount: i128) -> u32` — returns tx ID
- `approve(signer: Address, tx_id: u32)`
- `execute(tx_id: u32)` — executes if approvals >= threshold

## Expected Behavior
- Only registered signers can approve
- A signer cannot approve the same tx twice
- Execution fails if threshold not met
- Execution fails if tx already executed

## Hints
- Store transaction state: `{ to, amount, approvals, executed }`
- Use a `Vec<Address>` to track who has approved each tx
