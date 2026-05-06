#![no_std]
use soroban_sdk::{contract, contractimpl, Address, Env, String};

#[contract]
pub struct VotingContract;

#[contractimpl]
impl VotingContract {
    // TODO: Implement create_proposal(env: Env, title: String) -> u32

    // TODO: Implement vote(env: Env, voter: Address, proposal_id: u32)

    // TODO: Implement get_votes(env: Env, proposal_id: u32) -> u32
}
