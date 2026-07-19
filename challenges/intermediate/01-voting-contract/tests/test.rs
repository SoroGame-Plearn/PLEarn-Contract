#[cfg(test)]
mod tests {
    use crate::VotingContract;
    use soroban_sdk::{testutils::Address as _, Address, Env, String};

    #[test]
    fn test_vote_and_count() {
        let env = Env::default();
        let contract_id = env.register_contract(None, VotingContract);
        let client = VotingContractClient::new(&env, &contract_id);

        env.mock_all_auths();
        let proposal_id = client.create_proposal(&String::from_str(&env, "Proposal A"));
        let voter = Address::generate(&env);
        client.vote(&voter, &proposal_id);

        assert_eq!(client.get_votes(&proposal_id), 1);
    }

    #[test]
    #[should_panic]
    fn test_double_vote_rejected() {
        let env = Env::default();
        let contract_id = env.register_contract(None, VotingContract);
        let client = VotingContractClient::new(&env, &contract_id);

        env.mock_all_auths();
        let proposal_id = client.create_proposal(&String::from_str(&env, "Proposal B"));
        let voter = Address::generate(&env);
        client.vote(&voter, &proposal_id);
        client.vote(&voter, &proposal_id); // should panic
    }
}
