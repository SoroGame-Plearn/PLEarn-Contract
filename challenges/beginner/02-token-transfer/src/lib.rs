#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env};

#[contracttype]
pub enum DataKey {
    Admin,
    Balance(Address),
}

#[contracttype]
pub struct TransferEvent {
    pub from: Address,
    pub to: Address,
    pub amount: i128,
}

#[contract]
pub struct TokenTransfer;

#[contractimpl]
impl TokenTransfer {
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
    }

    pub fn mint(env: Env, to: Address, amount: i128) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();
        let current = Self::balance(env.clone(), to.clone());
        env.storage()
            .persistent()
            .set(&DataKey::Balance(to), &(current + amount));
    }

    pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
        from.require_auth();
        if amount < 0 {
            panic!("amount must be non-negative");
        }
        let from_balance = Self::balance(env.clone(), from.clone());
        if from_balance < amount {
            panic!("insufficient balance");
        }

        if from == to {
            // Self-transfer: balance remains the same, but we still emit an event
            env.events().publish(("transfer",), (from, to, amount));
        } else {
            let to_balance = Self::balance(env.clone(), to.clone());
            env.storage()
                .persistent()
                .set(&DataKey::Balance(from.clone()), &(from_balance - amount));
            env.storage()
                .persistent()
                .set(&DataKey::Balance(to.clone()), &(to_balance + amount));
            env.events().publish(("transfer",), (from, to, amount));
        }
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
    use soroban_sdk::{testutils::Address as _, Env};

    fn setup() -> (Env, TokenTransferClient<'static>, Address) {
        let env = Env::default();
        env.mock_all_auths();
        let id = env.register(TokenTransfer, ());
        let client = TokenTransferClient::new(&env, &id);
        let admin = Address::generate(&env);
        client.initialize(&admin);
        (env, client, admin)
    }

    #[test]
    fn test_transfer() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.mint(&alice, &500);
        client.transfer(&alice, &bob, &200);
        assert_eq!(client.balance(&alice), 300);
        assert_eq!(client.balance(&bob), 200);
    }

    #[test]
    #[should_panic(expected = "insufficient balance")]
    fn test_transfer_insufficient_balance() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.mint(&alice, &100);
        client.transfer(&alice, &bob, &500);
    }

    #[test]
    fn test_transfer_full_balance() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.mint(&alice, &300);
        client.transfer(&alice, &bob, &300);
        assert_eq!(client.balance(&alice), 0);
        assert_eq!(client.balance(&bob), 300);
    }

    #[test]
    fn test_self_transfer() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        client.mint(&alice, &500);
        client.transfer(&alice, &alice, &250);
        assert_eq!(client.balance(&alice), 500);
    }

    #[test]
    fn test_zero_amount_transfer() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.mint(&alice, &100);
        client.transfer(&alice, &bob, &0);
        assert_eq!(client.balance(&alice), 100);
        assert_eq!(client.balance(&bob), 0);
    }

    #[test]
    #[should_panic(expected = "amount must be non-negative")]
    fn test_negative_amount_transfer() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.mint(&alice, &100);
        client.transfer(&alice, &bob, &-50);
    }

    #[test]
    fn test_sequential_transfers() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        let charlie = Address::generate(&env);

        client.mint(&alice, &1000);

        // First transfer: Alice -> Bob (300)
        client.transfer(&alice, &bob, &300);
        assert_eq!(client.balance(&alice), 700);
        assert_eq!(client.balance(&bob), 300);
        assert_eq!(client.balance(&charlie), 0);

        // Second transfer: Bob -> Charlie (150)
        client.transfer(&bob, &charlie, &150);
        assert_eq!(client.balance(&alice), 700);
        assert_eq!(client.balance(&bob), 150);
        assert_eq!(client.balance(&charlie), 150);

        // Third transfer: Alice -> Charlie (200)
        client.transfer(&alice, &charlie, &200);
        assert_eq!(client.balance(&alice), 500);
        assert_eq!(client.balance(&bob), 150);
        assert_eq!(client.balance(&charlie), 350);

        // Fourth transfer: Charlie -> Bob (100)
        client.transfer(&charlie, &bob, &100);
        assert_eq!(client.balance(&alice), 500);
        assert_eq!(client.balance(&bob), 250);
        assert_eq!(client.balance(&charlie), 250);
    }

    #[test]
    #[should_panic(expected = "insufficient balance")]
    fn test_transfer_exceeds_balance_exact() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.mint(&alice, &250);
        client.transfer(&alice, &bob, &251);
    }

    #[test]
    #[should_panic(expected = "insufficient balance")]
    fn test_transfer_from_empty_account() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        client.transfer(&alice, &bob, &1);
    }

    #[test]
    fn test_account_state_consistency_after_transfers() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        let charlie = Address::generate(&env);

        let total = 1000i128;
        client.mint(&alice, &total);

        // Perform multiple transfers
        client.transfer(&alice, &bob, &200);
        client.transfer(&alice, &charlie, &300);
        client.transfer(&bob, &charlie, &100);

        // Verify total balance is conserved
        let sum = client.balance(&alice) + client.balance(&bob) + client.balance(&charlie);
        assert_eq!(sum, total);

        // Verify individual balances
        assert_eq!(client.balance(&alice), 500);
        assert_eq!(client.balance(&bob), 100);
        assert_eq!(client.balance(&charlie), 400);
    }

    #[test]
    fn test_large_amount_transfer() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        let large_amount = 9_223_372_036_854_775_807i128; // i128::MAX

        client.mint(&alice, &large_amount);
        client.transfer(&alice, &bob, &large_amount);

        assert_eq!(client.balance(&alice), 0);
        assert_eq!(client.balance(&bob), large_amount);
    }

    #[test]
    fn test_multiple_transfers_same_pairs() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);

        client.mint(&alice, &1000);

        // Multiple transfers between same pairs
        for i in 1..=5 {
            let amount = 100i128;
            client.transfer(&alice, &bob, &amount);
            assert_eq!(client.balance(&alice), 1000 - (i * amount));
            assert_eq!(client.balance(&bob), i * amount);
        }
    }

    #[test]
    fn test_circular_transfer_pattern() {
        let (env, client, _) = setup();
        let alice = Address::generate(&env);
        let bob = Address::generate(&env);
        let charlie = Address::generate(&env);

        client.mint(&alice, &300);

        // Create a circular transfer pattern
        client.transfer(&alice, &bob, &100);    // Alice: 200, Bob: 100, Charlie: 0
        client.transfer(&bob, &charlie, &50);   // Alice: 200, Bob: 50, Charlie: 50
        client.transfer(&charlie, &alice, &25); // Alice: 225, Bob: 50, Charlie: 25

        assert_eq!(client.balance(&alice), 225);
        assert_eq!(client.balance(&bob), 50);
        assert_eq!(client.balance(&charlie), 25);

        let total = client.balance(&alice) + client.balance(&bob) + client.balance(&charlie);
        assert_eq!(total, 300);
    }
}
