# Testing Strategy for PLEarn Soroban Contracts

A practical guide to writing, running, and debugging tests for the Soroban contracts in this
repository. Where the [Soroban SDK Quick Reference](./SOROBAN_SDK_QUICK_REFERENCE.md) covers SDK
*syntax*, this guide covers testing *strategy* — how to structure a test suite, how to simulate
the Soroban host environment, and how to be confident a contract is correct before it ships.

Every example below either comes directly from a challenge in this repo (verified by
`./scripts/run-tests.sh`) or follows the same idioms used by those tests, so you can copy-paste
and adapt with confidence.

---

## Table of Contents

1. [Where Tests Live](#where-tests-live)
2. [Anatomy of a Test](#anatomy-of-a-test)
3. [Mocking the Soroban Environment](#mocking-the-soroban-environment)
4. [Testing Common Patterns](#testing-common-patterns)
5. [Negative Testing: Panics & Rejections](#negative-testing-panics--rejections)
6. [Performance Testing Considerations](#performance-testing-considerations)
7. [Debugging Failing Tests](#debugging-failing-tests)
8. [Soroban SDK Test Utilities Reference](#soroban-sdk-test-utilities-reference)
9. [Pre-PR Testing Checklist](#pre-pr-testing-checklist)

---

## Where Tests Live

PLEarn contracts keep tests **inline**, in a `#[cfg(test)] mod tests { ... }` block at the bottom
of `src/lib.rs`, next to the code they exercise. The `tests/test.rs` file that Cargo also expects
is kept as a placeholder:

```rust
// Tests live in src/lib.rs (inline #[cfg(test)] module).
```

This is a deliberate convention across every challenge (see
[`beginner/01-hello-token/src/lib.rs`](../challenges/beginner/01-hello-token/src/lib.rs),
[`beginner/02-token-transfer/src/lib.rs`](../challenges/beginner/02-token-transfer/src/lib.rs)) —
it keeps the contract logic and the tests that prove it correct in one file, which matters for a
learning repo where the tests *are* the spec. When you add or fix tests for a challenge, add them
to `src/lib.rs`, not `tests/test.rs`.

Run a single challenge's tests with Cargo directly, or with the repo's validator script:

```bash
# Direct
cargo test --manifest-path challenges/beginner/02-token-transfer/Cargo.toml

# Wrapped (adds pass/fail framing used in CI)
./scripts/validate.sh challenges/beginner/02-token-transfer

# Every challenge, with a progress bar and JSON report
./scripts/run-tests.sh
```

### `test_snapshots/`

You'll notice a `test_snapshots/tests/*.json` file appears next to each test after it runs (see
[`beginner/02-token-transfer/test_snapshots/`](../challenges/beginner/02-token-transfer/test_snapshots/)).
The Soroban SDK test harness writes one automatically for every `#[test]` — it's a snapshot of the
mocked ledger state, storage entries, and authorized invocations at the end of the test. Commit
these alongside your test code; they're a cheap way to catch unintended changes in storage layout
or auth requirements during review (a diff in `test_snapshots/` on an unrelated PR is a signal
worth investigating).

---

## Anatomy of a Test

Every test in this repo follows the same shape: build an `Env`, register the contract, get a
typed client, then call functions through the client. A `setup()` helper avoids repeating the
first three steps in every test:

```rust
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
}
```

(Adapted from [`beginner/02-token-transfer/src/lib.rs`](../challenges/beginner/02-token-transfer/src/lib.rs).)

**What each piece does:**

| Piece | Purpose |
|---|---|
| `Env::default()` | Spins up an in-memory Soroban host — no network, no real ledger. |
| `env.mock_all_auths()` | Auto-approves every `require_auth()` call made during the test (see [Authorization](#authorization-requireauth)). |
| `env.register(Contract, ())` | Deploys the contract into the mocked environment and returns its `Address`. Older examples use `env.register_contract(None, Contract)` — both work; `register` is the current idiomatic form. |
| `ContractClient::new(&env, &id)` | The SDK auto-generates a `<Contract>Client` type from your `#[contractimpl]` block. Calling `client.foo(&args)` invokes the real contract function through the host, exactly as an external caller would. |
| `Address::generate(&env)` | Creates a random test-only address (requires the `testutils` feature, gated behind `soroban_sdk::testutils::Address`). |

Returning `(env, client, admin)` from `setup()` — rather than just `client` — matters: most tests
need `env` again to generate more addresses, and tests that check the `admin` path need it in
scope.

---

## Mocking the Soroban Environment

Soroban contracts run inside a host environment that provides storage, ledger metadata, and
authorization. `Env::default()` gives you a fully mocked version of that host so tests run in
milliseconds with no network. Three things are commonly mocked:

### 1. Authorization — mock everything, or mock precisely

`env.mock_all_auths()` is what every test in this repo uses — it makes every `require_auth()`
call succeed, regardless of who calls it. This is the right default for most tests, because the
thing under test is usually the contract's *business logic*, not the authorization framework
itself (which is enforced by the Soroban host, not your code).

When a test specifically needs to prove that only the *correct* address's authorization was
consumed — e.g. asserting a contract didn't accidentally require auth from the wrong party — use
`mock_auths` on the client for a single call instead of blanket-mocking everything:

```rust
use soroban_sdk::testutils::{Address as _, MockAuth, MockAuthInvoke};
use soroban_sdk::IntoVal;

#[test]
fn test_transfer_requires_senders_auth() {
    let env = Env::default();
    let id = env.register(TokenTransfer, ());
    let client = TokenTransferClient::new(&env, &id);
    let admin = Address::generate(&env);
    env.mock_all_auths();
    client.initialize(&admin);

    let alice = Address::generate(&env);
    let bob = Address::generate(&env);
    client.mint(&alice, &500);

    // Only mock auth for `alice` (the `from` address) on this specific call.
    client
        .mock_auths(&[MockAuth {
            address: &alice,
            invoke: &MockAuthInvoke {
                contract: &id,
                fn_name: "transfer",
                args: (alice.clone(), bob.clone(), 200i128).into_val(&env),
                sub_invokes: &[],
            },
        }])
        .transfer(&alice, &bob, &200);

    assert_eq!(client.balance(&bob), 200);
}
```

If `transfer` were changed to (incorrectly) call `bob.require_auth()` instead of
`from.require_auth()`, this test would fail with an auth error — a plain `mock_all_auths()` test
would not have caught it.

### 2. Ledger state — timestamps, sequence numbers, TTLs

Any contract logic based on time (deadlines, vesting, cooldowns) needs control over the mocked
ledger clock. Use `env.ledger().with_mut(...)`:

```rust
#[test]
fn test_voting_closes_after_deadline() {
    let env = Env::default();
    env.mock_all_auths();
    let id = env.register(VotingContract, ());
    let client = VotingContractClient::new(&env, &id);

    // Advance the mocked ledger's timestamp (seconds since epoch) and sequence number.
    env.ledger().with_mut(|li| {
        li.timestamp = 1_700_000_000;
        li.sequence_number = 1_000;
    });

    // ... call functions that read env.ledger().timestamp() and assert the deadline logic
}
```

`env.ledger()` also exposes read accessors used in production code, e.g.
`env.ledger().sequence()` and `env.ledger().timestamp()` — see
[SOROBAN_SDK_QUICK_REFERENCE.md § Environment Utilities](./SOROBAN_SDK_QUICK_REFERENCE.md#environment-utilities).

### 3. Reading storage directly, bypassing the client

Sometimes a test needs to assert on storage that the contract doesn't expose through a public
getter (or set up a state the public API can't reach directly, like a corrupted/legacy value).
Storage access only works "inside" a contract invocation, so wrap it in `env.as_contract(&id, ||
{...})`:

```rust
#[test]
fn test_admin_stored_correctly() {
    let (env, client, admin) = setup();
    let id = client.address.clone();

    let stored_admin: Address = env.as_contract(&id, || {
        env.storage().instance().get(&DataKey::Admin).unwrap()
    });

    assert_eq!(stored_admin, admin);
}
```

---

## Testing Common Patterns

### Authorization (`require_auth`)

Every function that changes state on someone's behalf should call `require_auth()` on the address
being acted for, and every such function needs at least one test proving unauthorized calls are
rejected. Because `mock_all_auths()` approves everyone, the way to prove auth is *required* (not
just present) is a `#[should_panic]` test with auth mocking turned off for the relevant address —
or, more simply, rely on the fact that omitting `mock_all_auths()` entirely means **no** call is
authorized, so any `require_auth()` in the path will panic:

```rust
#[test]
#[should_panic]
fn test_transfer_without_auth_fails() {
    let env = Env::default();
    let id = env.register(TokenTransfer, ());
    let client = TokenTransferClient::new(&env, &id);

    let admin = Address::generate(&env);
    env.mock_all_auths();
    client.initialize(&admin); // setup step, auth mocked here only

    // From here on, do NOT mock auths — the transfer below has none.
    let alice = Address::generate(&env);
    let bob = Address::generate(&env);
    client.transfer(&alice, &bob, &100); // panics: alice never authorized this
}
```

For the more surgical version — proving the *correct* address's auth was required — see the
`mock_auths` example in [Mocking the Soroban Environment](#1-authorization--mock-everything-or-mock-precisely)
above.

**Challenge examples:**
[`beginner/02-token-transfer`](../challenges/beginner/02-token-transfer/src/lib.rs) (`from.require_auth()` in `transfer`),
[`intermediate/02-access-control`](../challenges/intermediate/02-access-control/tests/test.rs) (`test_restricted_action_without_role`).

### Storage

Test both the read and write side of every storage key, plus the default/empty case:

```rust
#[test]
fn test_initial_balance_is_zero() {
    let (env, client, _) = setup();
    let user = Address::generate(&env);
    assert_eq!(client.balance(&user), 0); // unwrap_or(0) default, no panic
}

#[test]
fn test_mint_accumulates() {
    let (env, client, _) = setup();
    let user = Address::generate(&env);
    client.mint(&user, &300);
    client.mint(&user, &200);
    assert_eq!(client.balance(&user), 500); // confirms read-modify-write, not overwrite
}
```

(From [`beginner/01-hello-token/src/lib.rs`](../challenges/beginner/01-hello-token/src/lib.rs).)

For multi-party invariants (e.g. a token's total supply), assert conservation across every
balance after a sequence of operations, not just the two accounts directly involved:

```rust
#[test]
fn test_account_state_consistency_after_transfers() {
    let (env, client, _) = setup();
    let alice = Address::generate(&env);
    let bob = Address::generate(&env);
    let charlie = Address::generate(&env);

    let total = 1000i128;
    client.mint(&alice, &total);
    client.transfer(&alice, &bob, &200);
    client.transfer(&alice, &charlie, &300);
    client.transfer(&bob, &charlie, &100);

    let sum = client.balance(&alice) + client.balance(&bob) + client.balance(&charlie);
    assert_eq!(sum, total); // nothing was created or destroyed
}
```

(From [`beginner/02-token-transfer/src/lib.rs`](../challenges/beginner/02-token-transfer/src/lib.rs).)

### Events

Contracts publish events with `env.events().publish((topic,), data)` (see
[SOROBAN_SDK_QUICK_REFERENCE.md § Event Emission](./SOROBAN_SDK_QUICK_REFERENCE.md#event-emission)).
In tests, inspect what was published via `soroban_sdk::testutils::Events`:

```rust
use soroban_sdk::testutils::Events;
use soroban_sdk::{symbol_short, IntoVal};

#[test]
fn test_transfer_emits_event() {
    let (env, client, _) = setup();
    let alice = Address::generate(&env);
    let bob = Address::generate(&env);
    client.mint(&alice, &500);

    client.transfer(&alice, &bob, &200);

    let all_events = env.events().all();
    assert_eq!(all_events.len(), 1);
    assert_eq!(
        all_events,
        vec![
            &env,
            (
                client.address.clone(),
                (symbol_short!("transfer"),).into_val(&env),
                (alice, bob, 200i128).into_val(&env),
            ),
        ]
    );
}
```

`env.events().all()` returns every event published since the `Env` was created, in order —
including from cross-contract calls — so for multi-call tests, index into it (`all_events.get(0)`)
or clear/re-check between calls rather than assuming length 1.

---

## Negative Testing: Panics & Rejections

Every contract invariant deserves an explicit test that breaking it panics — not just a happy
path. Use `#[should_panic]`, and prefer the `expected = "..."` form so the test also verifies
you're panicking for the *right* reason (a typo'd condition that happens to panic elsewhere would
otherwise pass silently):

```rust
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
#[should_panic(expected = "already initialized")]
fn test_double_initialize_panics() {
    let (env, client, admin) = setup();
    client.initialize(&admin);
}
```

(From [`beginner/02-token-transfer`](../challenges/beginner/02-token-transfer/src/lib.rs) and
[`beginner/01-hello-token`](../challenges/beginner/01-hello-token/src/lib.rs).)

A negative-test checklist worth running through per contract function:

- **Boundary values**: exact-balance transfer (should succeed), one unit over balance (should
  panic) — see `test_transfer_exceeds_balance_exact` in
  [`beginner/02-token-transfer/src/lib.rs`](../challenges/beginner/02-token-transfer/src/lib.rs).
- **Empty/uninitialized state**: calling a function before `initialize()`, transferring from an
  account that never received funds (`test_transfer_from_empty_account`).
- **Invalid input**: negative amounts (`test_negative_amount_transfer`), zero where it's not
  meaningful, out-of-range enum/role values.
- **Repeated/duplicate actions**: double-vote (`test_double_vote_rejected` in
  [`intermediate/01-voting-contract`](../challenges/intermediate/01-voting-contract/tests/test.rs)),
  double-initialize.
- **Authorization bypass attempts**: acting on behalf of an address that didn't authorize it, or
  below a required threshold (`test_execute_below_threshold` in
  [`advanced/02-multisig-wallet`](../challenges/advanced/02-multisig-wallet/tests/test.rs)).

`#[should_panic]` without `expected` is acceptable for a quick check, but prefer adding the
message once the contract's panic strings stabilize — it turns a vague "something failed" test
into a precise regression guard.

---

## Performance Testing Considerations

Soroban meters every contract invocation by CPU instructions and memory, and mainnet enforces hard
resource limits. A contract that's logically correct but loops over an unbounded `Vec` in storage
(e.g. iterating every voter to check for a duplicate, as in
[`SOROBAN_SDK_QUICK_REFERENCE.md § Advanced: Maps and Vectors`](./SOROBAN_SDK_QUICK_REFERENCE.md#advanced-maps-and-vectors))
will pass tests locally with a handful of test addresses and then fail on-chain once real usage
scales up. A few things worth doing while writing tests, not after:

- **Exercise realistic scale in at least one test.** If a function iterates a collection, add a
  test with a loop that inserts dozens-to-hundreds of entries (see `test_multiple_transfers_same_pairs`
  in [`beginner/02-token-transfer/src/lib.rs`](../challenges/beginner/02-token-transfer/src/lib.rs)
  for the pattern of looping through repeated operations and asserting state at each step), not
  just 2-3 hardcoded addresses.
- **Inspect the mocked budget.** `Env` tracks CPU instruction and memory-byte cost as it executes,
  even in tests. Call `env.budget().print()` after invoking a contract function to see a
  breakdown:

  ```rust
  #[test]
  fn test_transfer_budget() {
      let (env, client, _) = setup();
      let alice = Address::generate(&env);
      let bob = Address::generate(&env);
      client.mint(&alice, &500);

      client.transfer(&alice, &bob, &200);

      env.budget().print(); // prints CPU instructions & memory used, run with `cargo test -- --nocapture`
  }
  ```

  Watch for a cost that grows with input size where it shouldn't (e.g. `mint`/`transfer` cost
  should stay roughly flat regardless of how many prior transfers happened, since balances are
  looked up by key, not scanned).
- **Prefer keyed lookups over scans.** Every challenge in this repo uses `DataKey::Balance(Address)`
  style enum keys precisely so storage reads/writes are O(1) regardless of how many accounts
  exist — avoid designs that require iterating a `Vec<Address>` to find one entry once a contract
  is meant to scale past a handful of users.
- **Check `env.storage().*.extend_ttl(...)` usage** for anything long-lived — an entry that
  expires unexpectedly in production because its TTL was never extended is a correctness bug that
  only performance/lifecycle-aware tests will catch. See
  [SOROBAN_SDK_QUICK_REFERENCE.md § Storage Management](./SOROBAN_SDK_QUICK_REFERENCE.md#storage-management).

The exact `Budget`/`cost_estimate` API surface has shifted across `soroban-sdk` releases — this
repo pins `soroban-sdk = "22.0.11"` (see any challenge's `Cargo.toml`); if `env.budget()` doesn't
match what's in your checked-out SDK version, run `cargo doc --open -p soroban-sdk --features
testutils` and search for `Budget` to see the exact methods available.

---

## Debugging Failing Tests

1. **Run just the failing test with output visible.**

   ```bash
   cargo test --manifest-path challenges/beginner/02-token-transfer/Cargo.toml \
     test_transfer_insufficient_balance -- --nocapture
   ```

   `--nocapture` is required to see `println!`/log output — by default `cargo test` swallows
   stdout for passing tests and only shows it for failures, so use it whenever you've added debug
   prints.

2. **Add contract-side logs with `soroban_sdk::log!`.** Unlike `println!`, `log!` works inside
   `#![no_std]` contract code and is stripped from real WASM builds, so it's safe to leave in
   while iterating:

   ```rust
   use soroban_sdk::log;

   pub fn transfer(env: Env, from: Address, to: Address, amount: i128) {
       from.require_auth();
       let from_balance = Self::balance(env.clone(), from.clone());
       log!(&env, "transfer: from_balance={}, amount={}", from_balance, amount);
       if from_balance < amount {
           panic!("insufficient balance");
       }
       // ...
   }
   ```

   Then print everything logged during the test:

   ```rust
   #[test]
   fn test_transfer_insufficient_balance() {
       let (env, client, _) = setup();
       // ... call client.transfer(...) ...
       env.logs().print(); // requires the `testutils` feature (already enabled in dev-dependencies)
   }
   ```

3. **Read the panic message, not just the test name.** `should_panic(expected = "...")` failures
   report the *actual* panic string when it doesn't match — that's almost always more informative
   than re-reading the contract code. Run with `RUST_BACKTRACE=1` for a full stack trace on
   unexpected panics:

   ```bash
   RUST_BACKTRACE=1 cargo test --manifest-path challenges/beginner/02-token-transfer/Cargo.toml
   ```

4. **Diff the `test_snapshots/` file.** If a test that touches storage or auth starts failing
   after a change that "shouldn't" affect it, compare the old and new `test_snapshots/tests/<test_name>.1.json`
   — a changed `ledger_entries` key or an extra `auth` entry pinpoints exactly what storage layout
   or authorization requirement shifted. See [`test_snapshots/`](#test_snapshots) above.

5. **Isolate with `setup()` in a scratch test.** When a failure is confusing, write a throwaway
   `#[test]` that only calls `setup()` and asserts the most basic post-condition (e.g. admin was
   stored). If that fails, the bug is in initialization, not the function you were originally
   debugging — narrowing the search space fast.

6. **Check for the common non-bugs first** — most "mysterious" failures in this repo are one of
   the entries in [SOROBAN_SDK_QUICK_REFERENCE.md § Troubleshooting Guide](./SOROBAN_SDK_QUICK_REFERENCE.md#troubleshooting-guide)
   (missing `mock_all_auths()`, using two different `Env`s, `.unwrap()` on an absent key).

---

## Soroban SDK Test Utilities Reference

- [`soroban_sdk::testutils` module docs](https://docs.rs/soroban-sdk/latest/soroban_sdk/testutils/index.html) —
  `Address`, `Events`, `Ledger`, `MockAuth`, `MockAuthInvoke`, `Logs`.
- [`soroban_sdk::Env` docs](https://docs.rs/soroban-sdk/latest/soroban_sdk/struct.Env.html) — full
  method list, including `register`, `as_contract`, `mock_all_auths`, `ledger`, `events`, `logs`,
  `budget`.
- [Soroban Docs — Write Tests](https://developers.stellar.org/docs/build/smart-contracts/getting-started/deploy-to-testnet)
  and [Soroban by Example](https://soroban.stellar.org/docs/learn/examples) — official worked
  examples beyond this repo's challenges.
- [`soroban-sdk` crate on docs.rs](https://docs.rs/soroban-sdk/) — pin the version dropdown to
  `22.0.11` (this repo's pinned version, see any challenge `Cargo.toml`) to match exact method
  signatures.
- [This repo's Soroban SDK Quick Reference](./SOROBAN_SDK_QUICK_REFERENCE.md) — storage, auth,
  events, and error-handling syntax used across every challenge.

---

## Pre-PR Testing Checklist

Before opening a PR that touches contract code:

- [ ] Every public function has at least one happy-path test and one `#[should_panic]` test.
- [ ] Storage getters are tested for both the populated and default/empty case.
- [ ] Every `require_auth()` call has a test proving the call fails without that address's
      authorization (see [Authorization](#authorization-requireauth)).
- [ ] Multi-step flows assert an invariant across *all* affected parties, not just the two most
      obviously involved (see [Storage](#storage)).
- [ ] `./scripts/validate.sh challenges/<path>` passes locally.
- [ ] `test_snapshots/` changes in the diff are intentional and reviewed, not incidental.
