#[cfg(test)]
mod tests {
    use soroban_sdk::{testutils::Address as _, Address, Env};
    use crate::StakingContract;

    #[test]
    fn test_stake_and_get_stake() {
        let env = Env::default();
        let contract_id = env.register_contract(None, StakingContract);
        let client = StakingContractClient::new(&env, &contract_id);

        let user = Address::generate(&env);
        env.mock_all_auths();
        client.stake(&user, &1000);

        assert_eq!(client.get_stake(&user), 1000);
    }

    #[test]
    fn test_unstake_returns_principal() {
        let env = Env::default();
        let contract_id = env.register_contract(None, StakingContract);
        let client = StakingContractClient::new(&env, &contract_id);

        let user = Address::generate(&env);
        env.mock_all_auths();
        client.stake(&user, &500);
        let returned = client.unstake(&user);

        assert!(returned >= 500); // at least principal returned
    }
}
