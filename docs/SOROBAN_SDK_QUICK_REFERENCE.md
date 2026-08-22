# Soroban SDK Quick Reference Guide

A quick reference covering essential Soroban SDK patterns used throughout PLEarn challenges. Each section includes verified code examples and links to the challenges that demonstrate these patterns.

---

## Table of Contents

1. [Storage Patterns](#storage-patterns)
2. [Address & Authentication](#address--authentication)
3. [Contract Invocation & Cross-Contract Calls](#contract-invocation--cross-contract-calls)
4. [Event Emission](#event-emission)
5. [Environment Utilities](#environment-utilities)
6. [Error Handling & Validation](#error-handling--validation)
7. [Testing Patterns](#testing-patterns)
8. [Troubleshooting Guide](#troubleshooting-guide)

---

## Storage Patterns

### Overview

Soroban provides persistent storage for contracts. Data is organized using `DataKey` enums and stored in two main areas:

- **Instance Storage** (`env.storage().instance()`) — Persistent data tied to a single contract instance. Used for configuration that rarely changes.
- **Persistent Storage** (`env.storage().persistent()`) — Long-term data storage. Used for balances, state, and records that need durability across invocations.

### Basic Storage: Using Enums as Keys

Define a `#[contracttype]` enum to structure your data keys:

```rust
#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env};

#[contracttype]
pub enum DataKey {
    Admin,                    // Single value key
    Balance(Address),         // Key with an address parameter
    ProposalCount,            // Counter key
    VoterList(u32),          // Key with numeric parameter
}

#[contract]
pub struct HelloToken;

#[contractimpl]
impl HelloToken {
    // Store admin in instance storage (set once, rarely changes)
    pub fn initialize(env: Env, admin: Address) {
        if env.storage().instance().has(&DataKey::Admin) {
            panic!("already initialized");
        }
        env.storage().instance().set(&DataKey::Admin, &admin);
    }

    // Retrieve admin from instance storage
    pub fn get_admin(env: Env) -> Address {
        env.storage()
            .instance()
            .get(&DataKey::Admin)
            .expect("Admin not initialized")
    }
}
```

**Key Concepts:**
- `env.storage().instance().set(&key, &value)` — Write to instance storage
- `env.storage().instance().get(&key)` — Read from instance storage (returns `Option`)
- `env.storage().instance().has(&key)` — Check if key exists
- Instance storage is efficient for data that doesn't change often

**Challenge Examples:**
- [`beginner/01-hello-token`](../challenges/beginner/01-hello-token/src/lib.rs) — Admin key in instance storage

### Persistent Storage: Balances and State

Use persistent storage for user data that changes frequently:

```rust
#[contractimpl]
impl HelloToken {
    pub fn mint(env: Env, to: Address, amount: i128) {
        let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
        admin.require_auth();

        // Read current balance from persistent storage
        let current: i128 = env
            .storage()
            .persistent()
            .get(&DataKey::Balance(to.clone()))
            .unwrap_or(0);  // Default to 0 if key doesn't exist

        // Write updated balance to persistent storage
        env.storage()
            .persistent()
            .set(&DataKey::Balance(to), &(current + amount));
    }

    pub fn balance(env: Env, account: Address) -> i128 {
        env.storage()
            .persistent()
            .get(&DataKey::Balance(account))
            .unwrap_or(0)
    }
}
```

**Key Concepts:**
- `env.storage().persistent().set(&key, &value)` — Write to persistent storage
- `env.storage().persistent().get(&key)` — Read from persistent storage (returns `Option`)
- `.unwrap_or(default)` — Provide a default if key doesn't exist
- Persistent storage survives contract invocations

**Challenge Examples:**
- [`beginner/01-hello-token`](../challenges/beginner/01-hello-token/src/lib.rs) — Balance tracking
- [`beginner/02-token-transfer`](../challenges/beginner/02-token-transfer/src/lib.rs) — Multiple balances

### Advanced: Maps and Vectors

For more complex data structures, Soroban SDK provides `Map` and `Vec`:

```rust
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, Map, Vec};

#[contracttype]
pub enum DataKey {
    Voters(u32),  // proposal_id → list of voters
    ProposalList,
}

#[contractimpl]
impl VotingContract {
    // Store voters for a proposal
    pub fn vote(env: Env, voter: Address, proposal_id: u32) {
        voter.require_auth();

        let mut voters: Vec<Address> = env
            .storage()
            .persistent()
            .get(&DataKey::Voters(proposal_id))
            .unwrap_or_else(|| Vec::new(&env));

        // Check voter hasn't already voted
        if voters.iter().any(|v| v == &voter) {
            panic!("already voted");
        }

        voters.push_back(voter);
        env.storage()
            .persistent()
            .set(&DataKey::Voters(proposal_id), &voters);
    }

    pub fn get_votes(env: Env, proposal_id: u32) -> u32 {
        env.storage()
            .persistent()
            .get(&DataKey::Voters(proposal_id))
            .map(|voters: Vec<Address>| voters.len() as u32)
            .unwrap_or(0)
    }
}
```

**Key Concepts:**
- `Vec::new(&env)` — Create a new vector
- `.push_back(item)` — Add to vector
- `.iter().any(|x| condition)` — Check if any element matches
- Vectors maintain insertion order
- Use `Symbol` keys for small strings to save space

**Challenge Examples:**
- `intermediate/01-voting-contract` — Tracking voters per proposal

---

## Address & Authentication

### Understanding Address

An `Address` represents a contract account on the Soroban network. It can be:
- **Account Address** — A user's account (e.g., from `Address::generate(&env)` in tests)
- **Contract Address** — A deployed contract ID

### Authentication with `require_auth()`

The `require_auth()` method verifies that an `Address` has authorized the current invocation:

```rust
pub fn mint(env: Env, to: Address, amount: i128) {
    let admin: Address = env.storage().instance().get(&DataKey::Admin).unwrap();
    
    // This will panic if the admin hasn't authorized this call
    admin.require_auth();
    
    // Safe to proceed — the admin authorized this mint
    env.storage()
        .persistent()
        .set(&DataKey::Balance(to), &amount);
}

pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
    // Caller must authorize to prevent unauthorized transfers
    from.require_auth();
    
    // Safe to transfer — `from` authorized the transfer
    let balance = Self::get_balance(env.clone(), from.clone());
    if balance < amount {
        panic!("insufficient balance");
    }
    
    // Update balances...
}
```

**Key Concepts:**
- `address.require_auth()` — Assert that `address` authorized this invocation
- Authorization is enforced by the Soroban host — you don't need to implement it
- Always call `require_auth()` for sensitive operations (transfers, admin actions)
- In tests, use `env.mock_all_auths()` to auto-authorize

**Challenge Examples:**
- [`beginner/01-hello-token`](../challenges/beginner/01-hello-token/src/lib.rs) — Admin authorization for minting
- [`beginner/02-token-transfer`](../challenges/beginner/02-token-transfer/src/lib.rs) — User authorization for transfers

### Generating Addresses in Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use soroban_sdk::{testutils::Address as _, Env};

    #[test]
    fn test_transfer() {
        let env = Env::default();
        env.mock_all_auths();  // Auto-authorize all addresses
        
        let id = env.register_contract(None, HelloToken);
        let client = HelloTokenClient::new(&env, &id);
        
        let alice = Address::generate(&env);  // Generate a random address
        let bob = Address::generate(&env);
        
        client.mint(&alice, &500);
        client.transfer(&alice, &bob, &200);
    }
}
```

**Key Concepts:**
- `Address::generate(&env)` — Create a random address (tests only)
- `env.mock_all_auths()` — Auto-authorize all addresses in tests
- Use `testutils::Address` trait for test utilities

---

## Contract Invocation & Cross-Contract Calls

### Calling Contract Functions

The Soroban SDK auto-generates client types for your contracts. Use them in tests:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use soroban_sdk::{testutils::Address as _, Env};

    #[test]
    fn test_initialization() {
        let env = Env::default();
        env.mock_all_auths();
        
        // Register the contract and get its ID
        let id = env.register_contract(None, HelloToken);
        
        // Create a client to call the contract
        let client = HelloTokenClient::new(&env, &id);
        
        let admin = Address::generate(&env);
        
        // Call initialize through the client
        client.initialize(&admin);
        
        // Verify by calling another function
        let balance = client.balance(&admin);
        assert_eq!(balance, 0);
    }
}
```

**Key Concepts:**
- `env.register_contract(None, ContractStruct)` — Deploy contract locally for testing
- `ContractClient::new(&env, &id)` — Create a client to call the contract
- Client methods match the contract's public functions
- Parameters are passed as references (e.g., `&amount`, `&address`)

**Challenge Examples:**
- [`beginner/01-hello-token`](../challenges/beginner/01-hello-token/tests/test.rs) — Using client to call functions
- [`beginner/02-token-transfer`](../challenges/beginner/02-token-transfer/tests/test.rs) — Multiple function calls

### Cross-Contract Calls (Advanced)

To invoke another contract from within your contract, use `Address::try_from_val()` and `Client` types generated by the SDK.

Example structure (not used in beginner challenges, but documented for completeness):

```rust
// In production, you would:
// 1. Get the other contract's address
// 2. Create a typed client for it
// 3. Call methods through the client
//
// This requires the other contract's types to be in scope.
```

---

## Event Emission

### Emitting Events

Events allow contracts to log important state changes for off-chain observers:

```rust
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, Symbol};

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
    pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
        from.require_auth();
        
        // Perform transfer...
        
        // Emit event
        let event = TransferEvent { from: from.clone(), to, amount };
        env.events().publish(("transfer",), event);
    }
}
```

**Key Concepts:**
- `env.events().publish((topic,), data)` — Emit an event
- Topics are a tuple of `Symbol` values (e.g., `("transfer",)`)
- Event data should be `#[contracttype]`-annotated
- Events are immutable after emission

**Note:** Event emission is not used in beginner challenges but is important for contract interfaces.

---

## Environment Utilities

### Ledger Information

Access ledger metadata through the environment:

```rust
pub fn contract_info(env: Env) {
    let ledger_info = env.ledger();
    
    let current_sequence = ledger_info.sequence();    // Current ledger sequence
    let max_ttl = ledger_info.max_live_until_ledger(); // Max time-to-live
    let min_temp_ttl = ledger_info.min_temp_entry_ttl(); // Min TTL for temporary entries
    let min_persist_ttl = ledger_info.min_persistent_entry_ttl(); // Min TTL for persistent
}
```

**Key Concepts:**
- `env.ledger().sequence()` — Current ledger sequence number
- Used for time-based logic (e.g., voting deadlines)
- TTL (time-to-live) controls how long data persists

### Storage Management

```rust
// Storage operations already covered in Storage Patterns section
let has_key = env.storage().instance().has(&DataKey::Admin);
env.storage().persistent().extend_ttl(&DataKey::Balance(addr), 1000, 2000);
```

### Current Contract Address

```rust
pub fn get_contract_address(env: Env) -> Address {
    env.current_contract_address()
}
```

---

## Error Handling & Validation

### Panicking with Messages

Use `panic!()` to halt execution and return an error to the caller:

```rust
pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
    from.require_auth();
    
    let balance = Self::get_balance(env.clone(), from.clone());
    
    // Validate: ensure sufficient balance
    if balance < amount {
        panic!("insufficient balance");
    }
    
    // Validate: prevent zero transfers
    if amount <= 0 {
        panic!("amount must be positive");
    }
    
    // Safe to proceed
    env.storage()
        .persistent()
        .set(&DataKey::Balance(from), &(balance - amount));
}
```

**Key Concepts:**
- `panic!(msg)` — Halt contract execution with an error message
- Error messages are returned to the caller
- Always validate inputs before proceeding
- Common validations: balance checks, authorization, non-zero amounts

**Common Error Scenarios:**

1. **Already Initialized**
   ```rust
   if env.storage().instance().has(&DataKey::Admin) {
       panic!("already initialized");
   }
   ```

2. **Insufficient Balance**
   ```rust
   if balance < amount {
       panic!("insufficient balance");
   }
   ```

3. **Duplicate Vote**
   ```rust
   if voters.iter().any(|v| v == &voter) {
       panic!("already voted");
   }
   ```

4. **Non-Existent Resource**
   ```rust
   let value = env.storage().persistent()
       .get(&key)
       .expect("proposal not found");
   ```

**Challenge Examples:**
- [`beginner/01-hello-token`](../challenges/beginner/01-hello-token/src/lib.rs) — "already initialized"
- [`beginner/02-token-transfer`](../challenges/beginner/02-token-transfer/src/lib.rs) — "insufficient balance"

---

## Testing Patterns

### Setup Pattern

A common pattern is to create a `setup()` function that initializes the contract for testing:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use soroban_sdk::{testutils::Address as _, Env};

    fn setup() -> (Env, HelloTokenClient<'static>, Address) {
        let env = Env::default();
        env.mock_all_auths();  // Mock all auth calls in tests
        
        let id = env.register_contract(None, HelloToken);
        let client = HelloTokenClient::new(&env, &id);
        
        let admin = Address::generate(&env);
        client.initialize(&admin);
        
        (env, client, admin)
    }

    #[test]
    fn test_basic_mint() {
        let (env, client, admin) = setup();
        let user = Address::generate(&env);
        
        client.mint(&user, &500);
        assert_eq!(client.balance(&user), 500);
    }
}
```

### Testing Panics

Use `#[should_panic]` to test error conditions:

```rust
#[test]
#[should_panic(expected = "already initialized")]
fn test_double_initialize_panics() {
    let (env, client, admin) = setup();
    client.initialize(&admin);  // First initialization
    client.initialize(&admin);  // Second should panic
}

#[test]
#[should_panic(expected = "insufficient balance")]
fn test_insufficient_balance() {
    let (env, client, _) = setup();
    let alice = Address::generate(&env);
    let bob = Address::generate(&env);
    
    client.mint(&alice, &100);
    client.transfer(&alice, &bob, &500);  // Should panic
}
```

### Best Practices

1. **Use setup functions** — DRY principle for test initialization
2. **Test happy paths first** — Verify normal operation
3. **Test edge cases** — Empty states, zero values, boundaries
4. **Test error conditions** — Panics, authorization failures
5. **Use descriptive names** — Test names should describe what they're testing

**Challenge Examples:**
- [`beginner/01-hello-token/tests`](../challenges/beginner/01-hello-token/tests/test.rs) — Comprehensive test suite
- [`beginner/02-token-transfer/tests`](../challenges/beginner/02-token-transfer/tests/test.rs) — Transfer and authorization tests

---

## Troubleshooting Guide

### Common Errors & Solutions

#### 1. **"Compilation Error: Unexpected imports or missing traits"**

**Problem:** Compiler says `contracttype` or `contract` macro is unknown.

**Solution:**
```rust
// Ensure these imports are present
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env};

// And that you're using #![no_std]
#![no_std]
```

#### 2. **"Storage key not found" (panic at runtime)**

**Problem:** Calling `.unwrap()` on a key that doesn't exist.

**Solution:**
```rust
// Wrong ❌
let value = env.storage().persistent().get(&key).unwrap();

// Right ✅ — provide a default
let value = env.storage().persistent()
    .get(&key)
    .unwrap_or(0);

// Or explicit error handling
let value = env.storage().persistent()
    .get(&key)
    .expect("value must be initialized");
```

#### 3. **"authorization failure" or "require_auth() failed"**

**Problem:** Address authorization check failed in production.

**Solution:**
- Ensure the transaction is signed by the address calling `require_auth()`
- In tests, use `env.mock_all_auths()` to skip authorization
- Verify the correct address is calling the function

#### 4. **"cannot move value of type `Address`"**

**Problem:** Rust borrow checker error when using addresses.

**Solution:**
```rust
// Wrong ❌
let admin = env.storage().instance().get(&DataKey::Admin).unwrap();
admin.require_auth();
env.storage().instance().set(&DataKey::Admin, &admin);  // moved!

// Right ✅ — use clone or reference
let admin = env.storage().instance().get(&DataKey::Admin).unwrap();
admin.require_auth();
let admin_clone = admin.clone();
env.storage().instance().set(&DataKey::Admin, &admin_clone);
```

#### 5. **"Vec/Map from a different Env"**

**Problem:** Creating a vector with one `Env` but using it with another.

**Solution:**
```rust
// Wrong ❌
let env1 = Env::default();
let env2 = Env::default();
let v = Vec::new(&env1);  // Created with env1
// Can't use v with env2

// Right ✅
let env = Env::default();
let v = Vec::new(&env);   // Use the same env
```

#### 6. **"Test passes locally but fails in CI"**

**Problem:** Test behavior differs between local and CI.

**Solution:**
- Ensure Rust version matches: `rustc --version`
- Check `Cargo.toml` has correct SDK version: `soroban-sdk = "22.0.11"`
- Verify all dependencies are pinned
- Run `cargo test` in a clean build: `cargo clean && cargo test`

#### 7. **"WASM compilation failed"**

**Problem:** Contract compiles as binary but not as WASM.

**Solution:**
- Verify target is installed: `rustup target add wasm32-unknown-unknown`
- Ensure `#![no_std]` is at the top of the file
- Check no platform-specific imports (e.g., `std::*`)
- Rebuild: `cargo clean && cargo build --target wasm32-unknown-unknown`

---

## Quick Reference Table

| Task | Code | Challenge |
|------|------|-----------|
| Store admin | `env.storage().instance().set(&DataKey::Admin, &admin)` | [01-hello-token](../challenges/beginner/01-hello-token/src/lib.rs) |
| Get admin | `env.storage().instance().get(&DataKey::Admin).unwrap()` | [01-hello-token](../challenges/beginner/01-hello-token/src/lib.rs) |
| Store balance | `env.storage().persistent().set(&DataKey::Balance(addr), &amount)` | [02-token-transfer](../challenges/beginner/02-token-transfer/src/lib.rs) |
| Get balance | `env.storage().persistent().get(&DataKey::Balance(addr)).unwrap_or(0)` | [02-token-transfer](../challenges/beginner/02-token-transfer/src/lib.rs) |
| Require auth | `address.require_auth()` | [01-hello-token](../challenges/beginner/01-hello-token/src/lib.rs) |
| Panic | `panic!("error message")` | [02-token-transfer](../challenges/beginner/02-token-transfer/src/lib.rs) |
| Register contract | `env.register_contract(None, Contract)` | [01-hello-token/tests](../challenges/beginner/01-hello-token/tests/test.rs) |
| Create client | `ContractClient::new(&env, &id)` | [01-hello-token/tests](../challenges/beginner/01-hello-token/tests/test.rs) |
| Mock all auths | `env.mock_all_auths()` | [01-hello-token/tests](../challenges/beginner/01-hello-token/tests/test.rs) |

---

## Additional Resources

- **Official Soroban Docs:** https://soroban.stellar.org/docs
- **Soroban SDK Reference:** https://docs.rs/soroban-sdk/
- **Soroban by Example:** https://soroban.stellar.org/docs/learn/examples
- **Stellar Developer Portal:** https://developers.stellar.org/
- **Stellar Developer Discord:** https://discord.gg/stellardev

---

## Contributing to This Guide

Found an issue or want to improve this guide? Please submit a PR or open an issue with:
- Code examples that need clarification
- New patterns not yet documented
- Troubleshooting scenarios you encountered

---

**Last Updated:** 2024
**Status:** Complete for Phase 1 (Beginner Challenges)
