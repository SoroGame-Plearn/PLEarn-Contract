#![no_std]
use soroban_sdk::{contract, contractimpl, Address, Env, Vec};

#[contract]
pub struct MultisigWallet;

#[contractimpl]
impl MultisigWallet {
    // TODO: Implement initialize(env: Env, signers: Vec<Address>, threshold: u32)

    // TODO: Implement submit_tx(env: Env, proposer: Address, to: Address, amount: i128) -> u32

    // TODO: Implement approve(env: Env, signer: Address, tx_id: u32)

    // TODO: Implement execute(env: Env, tx_id: u32)
}
