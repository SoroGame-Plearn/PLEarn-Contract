#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env};

#[contracttype]
pub enum DataKey {
    Admin,
    Balance(Address),
}

#[contract]
pub struct HelloToken;

#[contractimpl]
impl HelloToken {
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
    }

    pub fn mint(env: Env, to: Address, amount: i128) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        if amount < 0 {
            panic!("amount must be non-negative");
        }
        let current: i128 = env
            .storage()
            .persistent()
            .get(&DataKey::Balance(to.clone()))
            .unwrap_or(0);
        env.storage()
            .persistent()
            .set(&DataKey::Balance(to.clone()), &(current + amount));
        env.events().publish(("mint",), (to, amount));
    }

    pub fn balance(env: Env, account: Address) -> i128 {
        env.storage()
            .persistent()
            .get(&DataKey::Balance(account))
            .unwrap_or(0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use soroban_sdk::{
        testutils::{Address as _, Events, MockAuth, MockAuthInvoke},
        Env, FromVal, IntoVal,
    };

    fn setup() -> (Env, HelloTokenClient<'static>, Address) {
        let env = Env::default();
        env.mock_all_auths();
        let id = env.register(HelloToken, ());
        let client = HelloTokenClient::new(&env, &id);
        let admin = Address::generate(&env);
        client.initialize(&admin);
        (env, client, admin)
    }

    #[test]
    fn test_mint_and_balance() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &1000);
        assert_eq!(client.balance(&user), 1000);
    }

    #[test]
    fn test_initial_balance_is_zero() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        assert_eq!(client.balance(&user), 0);
    }

    #[test]
    fn test_mint_accumulates() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &300);
        client.mint(&user, &200);
        assert_eq!(client.balance(&user), 500);
    }

    /// Re-initializing an already-initialized contract must be rejected
    /// rather than silently replacing the admin, otherwise anyone able to
    /// call `initialize` again could hijack minting rights.
    #[test]
    #[should_panic(expected = "already initialized")]
    fn test_double_initialize_panics() {
        let (_env, client, admin) = setup();
        client.initialize(&admin);
    }

    /// Re-initializing with a *different* address must also be rejected,
    /// not just re-initializing with the same admin.
    #[test]
    #[should_panic(expected = "already initialized")]
    fn test_double_initialize_with_different_admin_panics() {
        let (env, client, _) = setup();
        let attacker = Address::generate(&env);
        client.initialize(&attacker);
    }

    /// Soroban addresses have no canonical "zero"/null representation the
    /// way some other chains do, so the closest meaningful edge case is
    /// minting to a special, non-user address: the token contract's own
    /// address. It should be treated like any other account.
    #[test]
    fn test_mint_to_contract_address() {
        let (_env, client, _) = setup();
        let contract_address = client.address.clone();
        client.mint(&contract_address, &42);
        assert_eq!(client.balance(&contract_address), 42);
    }

    /// Minting a negative amount would let the admin arbitrarily decrease a
    /// balance through what looks like a mint call. That must be rejected.
    #[test]
    #[should_panic(expected = "amount must be non-negative")]
    fn test_mint_negative_amount_panics() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &-100);
    }

    /// A negative mint must be rejected even against an account that
    /// already holds a balance, not only against a fresh account.
    #[test]
    #[should_panic(expected = "amount must be non-negative")]
    fn test_mint_negative_amount_with_existing_balance_panics() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &500);
        client.mint(&user, &-1);
    }

    #[test]
    fn test_mint_max_i128_value() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &i128::MAX);
        assert_eq!(client.balance(&user), i128::MAX);
    }

    /// Minting past `i128::MAX` must panic on arithmetic overflow rather
    /// than silently wrapping around, which would corrupt balances.
    #[test]
    #[should_panic]
    fn test_mint_overflow_panics() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &i128::MAX);
        client.mint(&user, &1);
    }

    /// Only the admin's authorization should allow minting. A caller that
    /// authorizes the invocation as a *different* address must not be able
    /// to mint, even though `require_auth` was satisfied for someone.
    #[test]
    fn test_non_admin_mint_fails_auth() {
        let env = Env::default();
        env.mock_all_auths();
        let id = env.register(HelloToken, ());
        let client = HelloTokenClient::new(&env, &id);
        let admin = Address::generate(&env);
        client.initialize(&admin);

        let non_admin = Address::generate(&env);
        let user = Address::generate(&env);

        env.mock_auths(&[MockAuth {
            address: &non_admin,
            invoke: &MockAuthInvoke {
                contract: &id,
                fn_name: "mint",
                args: (&user, 100i128).into_val(&env),
                sub_invokes: &[],
            },
        }]);

        let result = client.try_mint(&user, &100);
        assert!(result.is_err());
    }

    /// Calling mint with no authorization mocked at all must fail closed:
    /// the admin check must not be bypassable simply by omitting auth.
    #[test]
    fn test_mint_without_any_auth_fails() {
        let env = Env::default();
        let id = env.register(HelloToken, ());
        let client = HelloTokenClient::new(&env, &id);
        let admin = Address::generate(&env);

        env.mock_all_auths();
        client.initialize(&admin);
        env.set_auths(&[]);

        let user = Address::generate(&env);
        let result = client.try_mint(&user, &100);
        assert!(result.is_err());
    }

    /// Querying the balance of accounts that have never been minted to
    /// should consistently return 0, regardless of how many distinct
    /// never-touched accounts are queried.
    #[test]
    fn test_balance_of_multiple_non_existent_accounts_is_zero() {
        let (env, client, _) = setup();
        for _ in 0..5 {
            let account = Address::generate(&env);
            assert_eq!(client.balance(&account), 0);
        }
    }

    /// Parametrized-style check: a range of mint amounts, including the
    /// boundary value 0, all produce the expected balance.
    #[test]
    fn test_mint_various_amounts() {
        let scenarios: [i128; 5] = [0, 1, 100, 1_000_000, i128::MAX / 2];
        for amount in scenarios {
            let (env, client, _) = setup();
            let user = Address::generate(&env);
            client.mint(&user, &amount);
            assert_eq!(client.balance(&user), amount);
        }
    }

    #[test]
    fn test_mint_emits_event() {
        let (env, client, _) = setup();
        let user = Address::generate(&env);
        client.mint(&user, &777);

        let events = env.events().all();
        assert_eq!(events.len(), 1);
        let (contract_id, topics, data) = events.get(0).unwrap();
        assert_eq!(contract_id, client.address);
        assert_eq!(topics, ("mint",).into_val(&env));
        let (event_to, event_amount) = <(Address, i128)>::from_val(&env, &data);
        assert_eq!(event_to, user);
        assert_eq!(event_amount, 777i128);
    }
}
