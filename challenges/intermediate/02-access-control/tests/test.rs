#[cfg(test)]
mod tests {
    use soroban_sdk::{testutils::Address as _, symbol_short, Address, Env};
    use crate::AccessControl;

    #[test]
    fn test_grant_and_check_role() {
        let env = Env::default();
        let contract_id = env.register_contract(None, AccessControl);
        let client = AccessControlClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let user = Address::generate(&env);
        let role = symbol_short!("operator");

        env.mock_all_auths();
        client.initialize(&admin);
        client.grant_role(&admin, &user, &role);

        assert!(client.has_role(&user, &role));
    }

    #[test]
    fn test_revoke_role() {
        let env = Env::default();
        let contract_id = env.register_contract(None, AccessControl);
        let client = AccessControlClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let user = Address::generate(&env);
        let role = symbol_short!("operator");

        env.mock_all_auths();
        client.initialize(&admin);
        client.grant_role(&admin, &user, &role);
        client.revoke_role(&admin, &user, &role);

        assert!(!client.has_role(&user, &role));
    }

    #[test]
    #[should_panic]
    fn test_restricted_action_without_role() {
        let env = Env::default();
        let contract_id = env.register_contract(None, AccessControl);
        let client = AccessControlClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let user = Address::generate(&env);

        env.mock_all_auths();
        client.initialize(&admin);
        client.restricted_action(&user); // should panic
    }
}
