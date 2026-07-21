# PLEarn — Play. Learn. Earn.

> **Phase 1 MVP** — 2 of 6 challenges implemented (33%) · Wave submission ready

A hands-on Soroban smart contract challenge platform. Pick a challenge, write your contract, run the tests, and level up your Stellar/Soroban skills.

---

## What is PLEarn?

PLEarn is a learn-by-doing platform for Soroban smart contract development. Each challenge gives you:

- A clear objective and requirements
- Starter code with `TODO` stubs to fill in
- Pre-written tests that validate your solution automatically

No guessing whether your contract is correct — the tests tell you.

---

## Architecture

The diagram below shows how the pieces fit together: the challenge folders, the test harness that validates a solution, and the feedback loop a learner goes through from picking a challenge to seeing green tests.

![Diagram showing the PLEarn system architecture: a learner picks a challenge, reads its instructions, writes a solution in src/lib.rs, runs a validator script, and views pass/fail results; the validator scripts run cargo test against the challenge's Cargo.toml and test files, optionally generating an HTML report; a GitHub Actions workflow runs the same test harness on every push and pull request and reports status back to the PR.](docs/diagrams/architecture.svg)

*Diagram: PLEarn system architecture — created for [Issue #2](https://github.com/SoroGame-Plearn/PLEarn-Contract/issues/2), maintained in [`docs/diagrams/`](docs/diagrams/).*

For how an individual contract call behaves once it reaches the Soroban host — authorization, storage, and how unit tests simulate all of it locally — see the supplementary diagram:

![Diagram showing the Soroban contract lifecycle: a contract is written with the #[contract] and #[contractimpl] macros, compiled to a wasm32-unknown-unknown binary, loaded by the Soroban host environment, and invoked by a caller Address; inside an invocation, require_auth verifies the caller, the contract function body runs, contract storage is read or written, and a return value is sent back; local unit tests simulate the host environment and invocation using Env::default() and testutils, without needing a real network.](docs/diagrams/soroban-contract-lifecycle.svg)

*Diagram: Contract lifecycle in the Soroban environment.*

See [docs/diagrams/README.md](docs/diagrams/README.md) for the tools used and how to update these diagrams.

---

## Project Structure

```
PLEarn-Contract/
├── challenges/
│   ├── beginner/
│   │   ├── 01-hello-token/
│   │   │   ├── INSTRUCTIONS.md   # What to build
│   │   │   ├── Cargo.toml
│   │   │   ├── src/lib.rs        # Your solution goes here
│   │   │   └── tests/test.rs     # Pre-written tests
│   │   └── 02-token-transfer/
│   │       ├── INSTRUCTIONS.md
│   │       ├── Cargo.toml
│   │       ├── src/lib.rs
│   │       └── tests/test.rs
│   ├── intermediate/
│   │   ├── 01-voting-contract/
│   │   └── 02-access-control/
│   └── advanced/
│       ├── 01-staking-contract/
│       └── 02-multisig-wallet/
├── scripts/
│   ├── run-tests.sh              # Run all challenges
│   └── validate.sh               # Validate a single challenge
└── docs/
```

---

## Quick Start for Contributors ⚡

**Goal:** Get up and running in under 15 minutes!

### 1. Install Prerequisites

#### Rust (Required)
```bash
# Install Rust stable
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Add WebAssembly target (required for Soroban)
rustup target add wasm32-unknown-unknown
```

#### Verify Installation
```bash
rustc --version  # Should show stable version
cargo --version  # Should show matching version
```

### 2. Clone and Setup Project
```bash
git clone https://github.com/SoroGame-Plearn/PLEarn-Contract.git
cd PLEarn-Contract

# Test your setup with the first challenge
./scripts/validate.sh challenges/beginner/01-hello-token
```

**Expected output:**
```
🔍 Validating: challenges/beginner/01-hello-token
✅ Challenge passed!
```

### 3. Development Workflow

#### Running Tests
```bash
# Test specific challenge
./scripts/validate.sh challenges/beginner/01-hello-token

# Test all challenges
./scripts/run-tests.sh
```

#### Git Workflow
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes, then commit
git add .
git commit -m "feat: add voting contract challenge"

# Push and create PR
git push -u origin feature/your-feature-name
```

#### Commit Style
- `feat:` New features/challenges
- `fix:` Bug fixes  
- `docs:` Documentation updates
- `test:` Test improvements

### 4. Troubleshooting

#### Common Issues

**❌ "wasm32-unknown-unknown not found"**
```bash
rustup target add wasm32-unknown-unknown
```

**❌ "cargo test failed" on macOS**
```bash
# Install build essentials
xcode-select --install
```

**❌ "linker error" on Ubuntu/Debian**
```bash
sudo apt update
sudo apt install build-essential pkg-config
```

**❌ "permission denied" on Windows**
- Run terminal as Administrator
- Or use WSL2 with Ubuntu

**❌ Tests pass locally but fail in CI**
- Ensure Rust stable version
- Check `Cargo.toml` has correct `soroban-sdk = "22.0.11"`

#### Still Having Issues?

1. Check [Soroban Setup Guide](https://soroban.stellar.org/docs/getting-started/setup)
2. Verify [Rust Installation](https://www.rust-lang.org/tools/install)
3. Open an issue with your error output

### 5. Useful Resources

- 📖 [Soroban Documentation](https://soroban.stellar.org/docs) - Official docs
- 🚀 [Stellar Developer Portal](https://developers.stellar.org/) - Broader ecosystem
- 🎓 [Soroban by Example](https://soroban.stellar.org/docs/learn/examples) - Code examples
- 💬 [Stellar Developer Discord](https://discord.gg/stellardev) - Community help
- 📝 [Soroban SDK Reference](https://docs.rs/soroban-sdk/) - API documentation
- 🛠️ [Detailed Setup Guide](docs/SETUP_GUIDE.md) - Step-by-step installation

---

## Prerequisites

- [Rust](https://www.rust-lang.org/tools/install) (stable)
- Soroban target: `rustup target add wasm32-unknown-unknown`
- [Soroban CLI](https://soroban.stellar.org/docs/getting-started/setup) (optional, for deployment)

---

## Getting Started

### 1. Pick a challenge

Browse the `challenges/` folder. Start with `beginner/` if you're new to Soroban.

```
challenges/beginner/01-hello-token/INSTRUCTIONS.md
```

### 2. Read the instructions

Each challenge has an `INSTRUCTIONS.md` with:
- The objective
- Required functions to implement
- Expected behavior
- Hints

### 3. Write your solution

Open `src/lib.rs` and fill in the `TODO` stubs:

```rust
#[contractimpl]
impl HelloToken {
    pub fn initialize(env: Env, admin: Address) {
        // your code here
    }

    pub fn mint(env: Env, to: Address, amount: i128) {
        // your code here
    }

    pub fn balance(env: Env, account: Address) -> i128 {
        // your code here
    }
}
```

### 4. Validate your solution

```bash
./scripts/validate.sh challenges/beginner/01-hello-token
```

You'll see either:
```
✅ Challenge passed!
```
or a detailed test failure output showing exactly what went wrong.

### 5. Run all challenges

```bash
./scripts/run-tests.sh
```

---

## Challenges

### 🟢 Beginner

| # | Challenge | Status | Description |
|---|-----------|--------|-------------|
| 01 | Hello Token | ✅ Implemented | Mint a token and query balances |
| 02 | Token Transfer | ✅ Implemented | Add peer-to-peer transfer with auth |

### 🟡 Intermediate

| # | Challenge | Status | Description |
|---|-----------|--------|-------------|
| 01 | Voting Contract | 🔲 Open | On-chain proposals and voting |
| 02 | Access Control | 🔲 Open | Role-based permissions system |

### 🔴 Advanced

| # | Challenge | Status | Description |
|---|-----------|--------|-------------|
| 01 | Staking Contract | 🔲 Open | Stake tokens and earn time-based rewards |
| 02 | Multisig Wallet | 🔲 Open | M-of-N approval before executing transactions |

---

## Contributing

PLEarn is built in the open. Contributions are welcome across all skill levels. See [docs/contributing.md](docs/contributing.md) for the full guide.

### Ways to contribute

- **Add a new challenge** — Create a new folder under the appropriate difficulty level with `INSTRUCTIONS.md`, `src/lib.rs`, `tests/test.rs`, and `Cargo.toml`
- **Write test cases** — Improve coverage for existing challenges
- **Fix broken tests** — Find and fix tests that don't compile or have incorrect assertions
- **Improve instructions** — Make challenge descriptions clearer or add better hints

### Adding a new challenge

```
challenges/<difficulty>/<number>-<name>/
├── INSTRUCTIONS.md
├── Cargo.toml
├── src/
│   └── lib.rs        # starter code with TODO stubs
└── tests/
    └── test.rs       # pre-written tests
```

Follow the naming convention: `01-hello-token`, `02-token-transfer`, etc.

### Challenge checklist

- [ ] `INSTRUCTIONS.md` has a clear objective, requirements, expected behavior, and hints
- [ ] `src/lib.rs` has the contract struct, `#[contractimpl]` block, and `TODO` comments
- [ ] `tests/test.rs` covers the happy path and at least one failure case
- [ ] `Cargo.toml` uses `soroban-sdk = "22.0.11"` with `testutils` feature
- [ ] `./scripts/validate.sh challenges/<path>` runs without errors on a correct solution

---

## Scripts Reference

| Script | Usage | Description |
|--------|-------|-------------|
| `validate.sh` | `./scripts/validate.sh challenges/beginner/01-hello-token` | Test a single challenge |
| `run-tests.sh` | `./scripts/run-tests.sh` | Test all challenges |

---

## License

MIT
