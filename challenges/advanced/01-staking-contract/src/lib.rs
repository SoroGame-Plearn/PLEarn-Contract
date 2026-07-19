#![no_std]
// Imports kept for use when implementing the TODOs below.
#[allow(unused_imports)]
use soroban_sdk::{contract, contractimpl, Address, Env};

#[contract]
pub struct StakingContract;

#[contractimpl]
impl StakingContract {
    // TODO: Implement stake(env: Env, user: Address, amount: i128)

    // TODO: Implement unstake(env: Env, user: Address) -> i128

    // TODO: Implement get_stake(env: Env, user: Address) -> i128
}
