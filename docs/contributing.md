# Contributing to PLEarn

PLEarn is built in the open and contributions are welcome at every skill level.

---

## Quick Setup for New Contributors

### 1. Prerequisites Check

Before starting, ensure you have:

```bash
# Check Rust installation
rustc --version  # Should show 1.70+ (stable)
cargo --version  # Should match rustc version

# Check Soroban target
rustup target list --installed | grep wasm32-unknown-unknown
```

If missing, install:
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add Soroban target
rustup target add wasm32-unknown-unknown
```

### 2. Project Setup

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/PLEarn-Contract.git
cd PLEarn-Contract

# Add upstream remote
git remote add upstream https://github.com/SoroGame-Plearn/PLEarn-Contract.git

# Verify setup with first challenge
./scripts/validate.sh challenges/beginner/01-hello-token
```

### 3. Development Workflow

```bash
# Create feature branch
git checkout -b feature/descriptive-name

# Make your changes...

# Test your changes
./scripts/run-tests.sh

# Commit with conventional format
git add .
git commit -m "feat: add access control challenge"

# Push and create PR
git push -u origin feature/descriptive-name
```

### 4. Platform-Specific Setup

#### Windows

**Option 1: Native Windows**
```cmd
# Run PowerShell as Administrator
# Install Rust using rustup-init.exe from https://rustup.rs/
# Install Visual Studio C++ Build Tools or Visual Studio Community

rustup target add wasm32-unknown-unknown
```

**Option 2: WSL2 (Recommended)**
```bash
# In WSL2 Ubuntu terminal
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup target add wasm32-unknown-unknown
```

#### macOS

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add Soroban target
rustup target add wasm32-unknown-unknown
```

#### Linux (Ubuntu/Debian)

```bash
# Install build essentials
sudo apt update
sudo apt install build-essential pkg-config

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add Soroban target
rustup target add wasm32-unknown-unknown
```

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

## Troubleshooting Common Issues

### Compilation Errors

**"error: the `wasm32-unknown-unknown` target may not be installed"**
```bash
rustup target add wasm32-unknown-unknown
```

**"linker `cc` not found" (Linux)**
```bash
sudo apt install build-essential
```

**"Microsoft C++ Build Tools not found" (Windows)**
- Install Visual Studio Community or Build Tools for Visual Studio 2019+
- Or use WSL2 instead

### Runtime Errors

**"thread 'main' panicked at 'assertion failed'" in tests**
- Check your contract logic against the test expectations
- Add `println!()` debugging in tests (use `#[cfg(test)]`)

**"contract not found" errors**
- Ensure you're using `env.register_contract()` in test setup
- Check that contract struct name matches between impl and tests

### Performance Issues

**Very slow compilation on first run**
- This is normal - Rust/Soroban dependencies are large
- Subsequent builds will be much faster due to caching

**Out of memory during compilation**
- Try `export CARGO_BUILD_JOBS=1` to limit parallel builds
- Or increase your system RAM/swap

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

---

## Commit Style Guide

Follow conventional commits:

- `feat:` New features/challenges
- `fix:` Bug fixes
- `docs:` Documentation updates
- `test:` Test improvements
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

Examples:
```bash
git commit -m "feat: add multisig wallet challenge"
git commit -m "fix: correct test assertion in voting contract"
git commit -m "docs: improve troubleshooting section"
```

---

## Getting Help

1. 📖 [Soroban Documentation](https://soroban.stellar.org/docs) - Official docs
2. 💬 [Stellar Developer Discord](https://discord.gg/stellardev) - Community help
3. 🐛 Open an issue with detailed error output and system info
4. 📧 Tag maintainers in your PR for review
