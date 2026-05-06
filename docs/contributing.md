# Contributing to PLEarn

PLEarn is built in the open and contributions are welcome at every skill level.

---

## Wave Issues (Phase 1)

These are the open contribution tracks for the Wave submission:

| Track | What to do |
|-------|-----------|
| Add new challenges | Create a new challenge folder with instructions, starter code, and tests |
| Write test cases | Add more test coverage to existing challenges |
| Fix broken tests | Find and fix tests that fail or don't compile |
| Improve instructions | Clarify objectives, add hints, fix typos |

---

## Adding a New Challenge

### 1. Choose a difficulty and number

```
challenges/beginner/03-your-challenge/
challenges/intermediate/03-your-challenge/
challenges/advanced/03-your-challenge/
```

### 2. Create the required files

```
challenges/<difficulty>/<number>-<name>/
├── INSTRUCTIONS.md
├── Cargo.toml
├── src/
│   └── lib.rs        # contract struct + TODO stubs
└── tests/
    └── test.rs       # can be empty (// Tests in src/lib.rs)
```

### 3. Cargo.toml template

```toml
[package]
name = "your-challenge"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "rlib"]

[dependencies]
soroban-sdk = { version = "22.0.11" }

[dev-dependencies]
soroban-sdk = { version = "22.0.11", features = ["testutils"] }

[features]
testutils = ["soroban-sdk/testutils"]
```

### 4. INSTRUCTIONS.md template

```markdown
# Challenge: <Name>

## Difficulty: <Beginner | Intermediate | Advanced>

## Objective
One sentence description.

## Requirements
- Function signatures to implement

## Expected Behavior
- What passing tests verify

## Hints
- Useful SDK pointers
```

### 5. src/lib.rs pattern

```rust
#![no_std]
use soroban_sdk::{contract, contractimpl, Env};

#[contract]
pub struct YourContract;

#[contractimpl]
impl YourContract {
    // TODO: Implement foo(env: Env, ...) -> ...
}

#[cfg(test)]
mod tests {
    use super::*;
    use soroban_sdk::{testutils::Address as _, Env};

    #[test]
    fn test_happy_path() {
        // ...
    }

    #[test]
    #[should_panic]
    fn test_failure_case() {
        // ...
    }
}
```

### 6. Checklist before opening a PR

- [ ] `INSTRUCTIONS.md` has objective, requirements, expected behavior, and hints
- [ ] `src/lib.rs` has the contract struct and `TODO` stubs
- [ ] Tests cover at least one happy path and one failure case
- [ ] `./scripts/validate.sh challenges/<path>` passes on a correct solution
- [ ] Challenge is added to the table in `README.md`

---

## Fixing Tests

If a test doesn't compile or has a wrong assertion:

1. Run `./scripts/validate.sh challenges/<path>` to reproduce the failure
2. Fix the test in `src/lib.rs` under `#[cfg(test)]`
3. Verify with `cargo test -p <package-name>`

---

## Improving Instructions

Edit the `INSTRUCTIONS.md` in the challenge folder. Focus on:
- Making the objective unambiguous
- Adding concrete hints that point to SDK docs without giving away the answer
- Listing edge cases in "Expected Behavior"
