# PLEarn Setup Guide

This guide will get you from zero to running your first Soroban contract test in under 15 minutes.

## Prerequisites

### System Requirements
- **Operating System**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 18.04+/Debian 10+)
- **RAM**: 4GB minimum (8GB recommended for faster compilation)
- **Disk Space**: 2GB for Rust toolchain + dependencies
- **Internet**: Required for downloading dependencies

### Required Software
- [Git](https://git-scm.com/downloads)
- Rust toolchain (installed below)
- Code editor (VS Code, IntelliJ, or any text editor)

## Step-by-Step Installation

### 1. Install Rust

Choose your platform:

#### Windows

**Option A: WSL2 (Recommended)**
1. Install WSL2 with Ubuntu from Microsoft Store
2. Open Ubuntu terminal and follow Linux instructions below

**Option B: Native Windows**
1. Download rustup from https://rustup.rs/
2. Run `rustup-init.exe` as Administrator
3. Follow prompts (accept defaults)
4. Install Visual Studio Build Tools or Visual Studio Community
5. Restart terminal

#### macOS
```bash
# Install Xcode Command Line Tools (required for compilation)
xcode-select --install

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload shell environment
source ~/.cargo/env
```

#### Linux (Ubuntu/Debian)
```bash
# Install build essentials
sudo apt update
sudo apt install build-essential pkg-config curl

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload shell environment
source ~/.cargo/env
```

### 2. Add Soroban Target

All platforms:
```bash
rustup target add wasm32-unknown-unknown
```

### 3. Verify Installation

```bash
# Check versions (should show 1.70+)
rustc --version
cargo --version

# Verify WebAssembly target is installed
rustup target list --installed | grep wasm32
```

Expected output:
```
rustc 1.97.0 (2d8144b78 2026-07-07)
cargo 1.97.0 (c980f4866 2026-06-30)
wasm32-unknown-unknown
```

## Project Setup

### 1. Clone Repository

```bash
# Clone the project
git clone https://github.com/SoroGame-Plearn/PLEarn-Contract.git
cd PLEarn-Contract
```

### 2. Test Your Setup

Run the first challenge to verify everything works:

```bash
./scripts/validate.sh challenges/beginner/01-hello-token
```

**Success looks like:**
```
🔍 Validating: challenges/beginner/01-hello-token
   Compiling hello-token v0.1.0
    Finished test profile
     Running unittests src/lib.rs

running 4 tests
test tests::test_initial_balance_is_zero ... ok
test tests::test_double_initialize_panics - should panic ... ok
test tests::test_mint_and_balance ... ok
test tests::test_mint_accumulates ... ok

test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filter

✅ Challenge passed!
```

### 3. Test Both Implemented Challenges

```bash
# Test the basic token contract
./scripts/validate.sh challenges/beginner/01-hello-token

# Test the token transfer contract
./scripts/validate.sh challenges/beginner/02-token-transfer
```

Both should pass with "✅ Challenge passed!"

## Common Issues & Solutions

### "wasm32-unknown-unknown not found"

**Problem**: Missing WebAssembly compilation target
**Solution**:
```bash
rustup target add wasm32-unknown-unknown
```

### "linker 'cc' not found" (Linux)

**Problem**: Missing C compiler
**Solution**:
```bash
sudo apt install build-essential
```

### "Microsoft C++ Build Tools" error (Windows)

**Problem**: Missing Visual Studio build tools
**Solutions**:
1. Install Visual Studio Community (free)
2. Or install Build Tools for Visual Studio 2022
3. Or use WSL2 instead

### "cargo test failed" on macOS

**Problem**: Missing Xcode command line tools
**Solution**:
```bash
xcode-select --install
```

### Slow first compilation

**This is normal!** The first compilation downloads and compiles all Soroban dependencies (~600MB). Subsequent builds are much faster due to caching.

To speed up:
- Close other applications to free RAM
- On slower machines: `export CARGO_BUILD_JOBS=1`

### "Permission denied" errors

**On Windows**: Run terminal as Administrator
**On Linux/macOS**: Check file permissions with `ls -la`

### Tests pass locally but fail in CI

**Check**:
- You're using Rust stable (not beta/nightly)
- `Cargo.toml` has correct Soroban SDK version: `22.0.11`
- All files are committed to git

## Development Workflow

### Create Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### Make Changes
- Edit files in your preferred editor
- Follow existing code patterns

### Test Your Changes
```bash
# Test specific challenge
./scripts/validate.sh challenges/beginner/01-hello-token

# Test all working challenges
./scripts/validate.sh challenges/beginner/01-hello-token
./scripts/validate.sh challenges/beginner/02-token-transfer
```

### Commit Changes
```bash
git add .
git commit -m "feat: add new challenge"
```

### Push and Create PR
```bash
git push -u origin feature/your-feature-name
# Then create PR on GitHub
```

## Next Steps

Once setup is complete:

1. **Explore challenges**: Start with `challenges/beginner/01-hello-token/INSTRUCTIONS.md`
2. **Read Soroban docs**: https://soroban.stellar.org/docs
3. **Join community**: https://discord.gg/stellardev
4. **Contribute**: See `docs/contributing.md` for detailed guide

## Getting Help

If you're stuck:

1. **Check this guide** for common issues
2. **Search existing issues** on GitHub
3. **Open a new issue** with:
   - Your operating system
   - Complete error output
   - Output of `rustc --version`
4. **Ask in Discord**: https://discord.gg/stellardev

---

🎉 **Ready to build on Soroban!** Start with your first challenge: `challenges/beginner/01-hello-token/INSTRUCTIONS.md`
