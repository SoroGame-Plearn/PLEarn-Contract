#[cfg(test)]
mod tests {
    use soroban_sdk::{testutils::Address as _, vec, Address, Env};
    use crate::MultisigWallet;

    #[test]
    fn test_submit_and_approve() {
        let env = Env::default();
        let contract_id = env.register_contract(None, MultisigWallet);
        let client = MultisigWalletClient::new(&env, &contract_id);

        let s1 = Address::generate(&env);
        let s2 = Address::generate(&env);
        let recipient = Address::generate(&env);

        env.mock_all_auths();
        client.initialize(&vec![&env, s1.clone(), s2.clone()], &2);
        let tx_id = client.submit_tx(&s1, &recipient, &100);
        client.approve(&s1, &tx_id);
        client.approve(&s2, &tx_id);
        client.execute(&tx_id);
    }

    #[test]
    #[should_panic]
    fn test_execute_below_threshold() {
        let env = Env::default();
        let contract_id = env.register_contract(None, MultisigWallet);
        let client = MultisigWalletClient::new(&env, &contract_id);

        let s1 = Address::generate(&env);
        let s2 = Address::generate(&env);
        let recipient = Address::generate(&env);

        env.mock_all_auths();
        client.initialize(&vec![&env, s1.clone(), s2.clone()], &2);
        let tx_id = client.submit_tx(&s1, &recipient, &100);
        client.approve(&s1, &tx_id);
        client.execute(&tx_id); // only 1 approval, threshold is 2 — should panic
    }
}
