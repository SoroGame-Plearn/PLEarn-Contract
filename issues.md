# PLEarn GitHub Issues — Contributor Roadmap

## Phase 1: Foundation & Infrastructure (Issues 1-6)

---

## [Infra] Set up GitHub Actions workflow for contract tests

**Description:**
Automate contract testing on every push and PR to ensure code quality and prevent regressions.

**Tasks:**
- Create `.github/workflows/contract-tests.yml`
- Install Rust toolchain and `wasm32-unknown-unknown` target
- Run `cargo test` for all challenges (beginner, intermediate, advanced)
- Run `cargo clippy` for linting
- Run `cargo fmt --check` for formatting
- Cache Rust dependencies to speed up CI runs
- Report test results and coverage metrics in PR comments

**Success Criteria:**
- All workflows pass on merge to main
- Tests run in under 5 minutes
- Clippy and fmt checks pass without warnings

---

## [Docs] Add comprehensive architecture diagram

**Description:**
Create a visual overview of the PLEarn system showing the relationship between challenges, testing infrastructure, and learner workflow.

**Tasks:**
- Design diagram showing: Challenge structure, contract module flow, test harness, learner feedback loop
- Show how validators execute and report test results
- Include data flow for typical learner journey (pick challenge → write code → run tests → view results)
- Export as SVG and embed in README.md with alt text
- Create supplementary diagram for contract lifecycle in Soroban environment
- Document diagram update process for future contributors

**Success Criteria:**
- Diagram is clear and understandable to beginners
- All system components are represented
- Embedded in README with proper attribution

---

## [Docs] Create contributor onboarding guide

**Description:**
New contributors should be able to get up and running with the project in under 15 minutes.

**Tasks:**
- Document local setup: Rust installation, target setup, dependency installation
- Create step-by-step guide for running first challenge
- Document development workflow (git branching, commit style, PR process)
- Add troubleshooting section for common setup issues (Windows/macOS/Linux differences)
- Include links to Soroban docs and relevant Stellar resources
- Create video walkthrough (optional) showing environment setup

**Success Criteria:**
- New contributor can run `./scripts/validate.sh` without errors within 15 minutes
- README includes "Quick Start for Contributors" section
- Troubleshooting resolves 80% of common issues

---

## [Scripts] Enhance run-tests.sh with progress tracking

**Description:**
Improve the test runner to show real-time progress, summary statistics, and detailed failure reports.

**Tasks:**
- Add progress bar showing challenges completed vs total
- Display pass/fail count as tests run
- Show estimated time remaining
- Generate JSON report with test timings per challenge
- Add color-coded output (green for pass, red for fail, yellow for warnings)
- Include summary showing: total tests, passed, failed, skipped
- Log test artifacts to `.test-artifacts/` for debugging

**Success Criteria:**
- Script runs all tests and produces colored summary output
- JSON report accurately captures all test metadata
- Execution time is tracked per challenge

---

## [Scripts] Create challenge validation tool with detailed feedback

**Description:**
Build an enhanced validator that gives learners precise, actionable feedback when tests fail.

**Tasks:**
- Create `scripts/validate-detailed.sh` that parses test output
- Show which test cases passed vs failed
- Extract and display assertion messages from failed tests
- Suggest next steps based on failure patterns
- Generate HTML report of test results (optional)
- Add `--watch` mode for continuous validation on file changes
- Include estimated difficulty rating and time to solve

**Success Criteria:**
- Feedback message is clear and actionable
- Learner can understand exactly what went wrong
- `--watch` mode reruns tests on any `.rs` file change

---

## [Docs] Write comprehensive testing strategy document

**Description:**
Document best practices for writing tests for Soroban contracts, with examples from PLEarn.

**Tasks:**
- Explain testing patterns used in PLEarn challenges
- Document how to mock Soroban environment (env, storage, ledger)
- Create section on testing common patterns: auth, storage, events
- Add examples of negative test cases (panics, rejections)
- Document performance testing considerations
- Show how to debug failing tests using log output
- Include links to Soroban SDK test utilities documentation

**Success Criteria:**
- Document is in `docs/testing-guide.md`
- Examples are copy-paste ready and tested
- Covers all testing patterns used in existing challenges

---

## Phase 2: Beginner Challenges (Issues 7-12)

---

## [Challenge] Implement 03-token-metadata challenge

**Description:**
Extend the token system to support metadata (name, symbol, decimals) and querying.

**Tasks:**
- Create `challenges/beginner/03-token-metadata/` directory
- Write INSTRUCTIONS.md with requirements:
  - `set_metadata(name: String, symbol: String, decimals: u32)`
  - `get_name() -> String`
  - `get_symbol() -> String`
  - `get_decimals() -> u32`
- Implement starter code with TODO stubs
- Write comprehensive test cases covering:
  - Setting metadata multiple times (should reject or overwrite)
  - Querying metadata before it's set (should panic or return default)
  - Unicode in name/symbol strings
  - Boundary values for decimals
- Verify tests pass with correct implementation

**Success Criteria:**
- Challenge follows naming convention and directory structure
- At least 5 test cases covering happy path and edge cases
- INSTRUCTIONS clearly describe requirements and hints
- Tests pass with correct implementation

---

## [Challenge] Implement 04-token-supply challenge

**Description:**
Add total supply tracking and burn functionality to the token system.

**Tasks:**
- Create `challenges/beginner/04-token-supply/` directory
- Write INSTRUCTIONS.md with requirements:
  - `total_supply() -> i128`
  - `burn(from: Address, amount: i128)` — admin only
  - Supply increases on mint, decreases on burn
- Implement starter code with TODO stubs and partial implementation
- Write test cases for:
  - Minting increases supply
  - Burning decreases supply
  - Non-admin cannot burn
  - Cannot burn more than balance
  - Burning leaves balances unchanged (only total supply affected)
- Validate against regressions from earlier challenges

**Success Criteria:**
- Builds on previous token challenges while introducing burn logic
- Test suite prevents common mistakes (unauthorized burn, overspend)
- Challenge is solvable in 20-30 minutes for learners at this level

---

## [Challenge] Implement 05-multi-token-wallet challenge

**Description:**
Build a wallet contract that can hold multiple different tokens.

**Tasks:**
- Create `challenges/beginner/05-multi-token-wallet/` directory
- INSTRUCTIONS.md requirements:
  - `deposit(token_address: Address, amount: i128)`
  - `withdraw(token_address: Address, amount: i128)`
  - `balance(token_address: Address) -> i128`
  - Support for arbitrary token addresses (cross-contract calls)
- Provide starter code with TODO stubs for:
  - Storage structure for multiple token balances
  - Token interface for deposit/withdraw calls
- Write test cases:
  - Deposit from multiple tokens
  - Withdraw from one token doesn't affect others
  - Cannot withdraw more than deposited
  - Non-existent tokens handled gracefully
- Document cross-contract call patterns in hints

**Success Criteria:**
- Learners understand token abstraction and contract interaction
- Tests validate isolation between token balances
- Hints guide learners on calling external contracts

---

## [Challenge] Write comprehensive tests for 01-hello-token

**Description:**
Expand test coverage for the Hello Token challenge to include edge cases and security scenarios.

**Tasks:**
- Review current tests in `challenges/beginner/01-hello-token/tests/test.rs`
- Add tests for:
  - Initializing twice (should reject or replace admin)
  - Minting to zero address
  - Minting negative amounts
  - Minting max i128 value
  - Non-admin attempting to mint
  - Admin querying non-existent accounts
  - Event emission on mint (if applicable)
- Ensure tests are well-documented with clear names
- Add parametrized tests for multiple scenarios
- Update INSTRUCTIONS.md with coverage note

**Success Criteria:**
- Test count increases from current baseline to at least 12 tests
- All tests pass with correct implementation
- Edge cases are explicitly covered

---

## [Challenge] Write comprehensive tests for 02-token-transfer

**Description:**
Expand test coverage for the Token Transfer challenge with authorization and edge case scenarios.

**Tasks:**
- Review current tests in `challenges/beginner/02-token-transfer/tests/test.rs`
- Add tests for:
  - Transferring between same address (self-transfer)
  - Transferring zero amount
  - Transferring more than balance
  - Multiple transfers in sequence
  - Authorization failure without proper auth
  - Transfer events are emitted correctly
  - Account state after multiple transfers
- Add fuzzing or property-based tests for transfer correctness
- Document assumptions about transfer semantics

**Success Criteria:**
- Test count increases significantly with edge cases
- Authorization is thoroughly tested
- State transitions are verified

---

## [Docs] Create Soroban SDK quick reference guide

**Description:**
Provide a quick reference for common Soroban SDK patterns used across PLEarn challenges.

**Tasks:**
- Create `docs/soroban-sdk-reference.md` documenting:
  - Storage patterns (Map, Vec, Symbol as key)
  - Address and auth patterns (Address::require_auth())
  - Contract invocation and cross-contract calls
  - Event emission
  - Environment utilities (env.ledger(), env.storage())
  - Common error patterns and panics
- Include code examples from actual PLEarn challenges
- Organize by use case (auth, storage, time, events)
- Link to official Soroban documentation for deeper dives
- Add troubleshooting section for common SDK errors

**Success Criteria:**
- Reference covers all patterns used in beginner challenges
- Examples are accurate and tested
- New contributors can find answers without searching Soroban docs

---

## Phase 3: Intermediate Challenges (Issues 13-20)

---

## [Challenge] Implement 01-voting-contract with complete test suite

**Description:**
Build and fully test the on-chain voting contract with proposal tracking and vote validation.

**Tasks:**
- Review and expand `challenges/intermediate/01-voting-contract/src/lib.rs` with:
  - Proposal struct (id, title, creator, vote_count, is_active)
  - Vote tracking per proposal
  - Deadline enforcement (if added)
- Write comprehensive test suite (15+ tests) covering:
  - Creating proposals
  - Casting votes (single and multiple)
  - Preventing duplicate votes from same address
  - Vote count accuracy
  - Non-existent proposal handling
  - Proposal listing/querying
  - Edge cases (large vote counts, proposal title edge cases)
- Add benchmarking tests for performance validation
- Document assumptions about proposal lifecycle

**Success Criteria:**
- All tests pass with correct implementation
- Duplicate vote prevention is thoroughly tested
- Performance is acceptable for 1000+ proposals

---

## [Challenge] Implement 02-access-control with role hierarchy

**Description:**
Build a sophisticated access control system supporting role-based permissions and hierarchies.

**Tasks:**
- Expand `challenges/intermediate/02-access-control/src/lib.rs` with:
  - Role struct with permissions (admin, moderator, user)
  - Role assignment mechanism
  - Role verification before sensitive operations
  - Role hierarchy (admin > moderator > user)
  - Role revocation
- Write test suite (20+ tests) for:
  - Assigning roles
  - Role-based access denial
  - Role hierarchy enforcement
  - Revoking roles
  - Re-assigning roles
  - Multiple permissions per role
  - Concurrent role checks
- Add documentation for role definitions
- Consider gas/performance implications

**Success Criteria:**
- Role hierarchy is enforced correctly in all tests
- Unauthorized access attempts are caught
- Role transitions are atomic

---

## [Challenge] Create 03-escrow-contract challenge

**Description:**
Build an escrow contract for trustless peer-to-peer transactions.

**Tasks:**
- Create `challenges/intermediate/03-escrow-contract/` directory
- INSTRUCTIONS.md with requirements:
  - `create_escrow(buyer: Address, seller: Address, amount: i128) -> u32` — returns escrow ID
  - `release_funds(escrow_id: u32)` — seller releases payment to buyer
  - `refund_escrow(escrow_id: u32)` — buyer cancels and gets refund
  - `get_escrow_status(escrow_id: u32) -> Status` (Pending, Released, Refunded)
- Implement starter code with TODO stubs
- Write 15+ tests:
  - Creating escrow reserves funds
  - Both parties must authorize transactions
  - Release only by seller or authorized party
  - Refund only by buyer or authorized party
  - State transitions are irreversible
  - Funds are correctly transferred
  - Escrow timeout handling (if applicable)
- Document trust model and authorization flow

**Success Criteria:**
- Escrow state machine is correct
- Authorization is properly enforced
- No fund loss or duplication occurs

---

## [Challenge] Create 04-nft-minting challenge

**Description:**
Introduce NFT (non-fungible token) minting with metadata and ownership tracking.

**Tasks:**
- Create `challenges/intermediate/04-nft-minting/` directory
- INSTRUCTIONS.md with requirements:
  - `mint_nft(to: Address, uri: String) -> u32` — returns token ID
  - `owner_of(token_id: u32) -> Address`
  - `transfer_nft(from: Address, to: Address, token_id: u32)` — with auth
  - `get_metadata(token_id: u32) -> String`
- Implement starter code with:
  - NFT struct (id, owner, uri, created_at)
  - Token ID counter
  - TODO stubs for core functions
- Write 15+ test cases:
  - Minting increments ID correctly
  - Owner is tracked properly
  - Transfer updates ownership
  - Non-owner cannot transfer
  - Metadata retrieval
  - Edge cases (transferring to self, non-existent token)
  - Batch operations (optional)

**Success Criteria:**
- Ownership model is correct
- Authorization prevents unauthorized transfers
- Metadata is correctly associated with tokens

---

## [Challenge] Create 05-liquidity-pool-basics challenge

**Description:**
Introduce basic liquidity pool concepts with simple AMM (Automated Market Maker) logic.

**Tasks:**
- Create `challenges/intermediate/05-liquidity-pool-basics/` directory
- INSTRUCTIONS.md with requirements:
  - `add_liquidity(token_a: Address, token_b: Address, amount_a: i128, amount_b: i128) -> i128` — returns LP tokens
  - `remove_liquidity(lp_token_amount: i128) -> (i128, i128)` — returns token amounts
  - `swap(from_token: Address, to_token: Address, amount: i128) -> i128`
  - `get_reserves() -> (i128, i128)`
- Implement starter code with:
  - Pool struct tracking reserves and LP token supply
  - Constant product formula stub (x * y = k)
  - TODO stubs for functions
- Write 15+ tests:
  - Adding liquidity mints LP tokens correctly
  - Removing liquidity burns LP tokens
  - Swaps maintain constant product
  - Slippage handling (if required)
  - Edge cases (first liquidity, zero amounts)
  - Price calculations
  - Event emission

**Success Criteria:**
- Constant product formula is maintained
- No arbitrage opportunities from rounding errors
- LP token math is correct

---

## [Challenge] Create 06-time-lock-contract challenge

**Description:**
Build a time-locked vault for scheduled token releases.

**Tasks:**
- Create `challenges/intermediate/06-time-lock-contract/` directory
- INSTRUCTIONS.md with requirements:
  - `lock_tokens(token: Address, amount: i128, unlock_time: u64)`
  - `unlock_tokens() -> i128` — withdraw if time has passed
  - `get_unlock_time() -> u64`
  - `get_locked_amount() -> i128`
- Implement starter code with:
  - Lock struct (amount, unlock_ledger, recipient)
  - Ledger-based time tracking
  - TODO stubs
- Write 15+ tests:
  - Locking prevents withdrawal
  - Unlock only works after time passes
  - Correct amount is released
  - Multiple locks per address
  - Early unlock attempts fail
  - Time calculation accuracy
  - Ledger boundary conditions

**Success Criteria:**
- Time-based conditions are enforced
- No premature or delayed releases
- Ledger tracking is accurate

---

## [Challenge] Create comprehensive test suite template

**Description:**
Provide a reusable test suite template for intermediate challenges that new challenge creators can use.

**Tasks:**
- Create `templates/test-suite-intermediate.rs` with:
  - Boilerplate for test initialization
  - Helper functions for common test patterns
  - Setup/teardown utilities
  - Mock data generators
  - Assertion helpers for contract errors
- Document:
  - How to extend the template for new challenges
  - Common test patterns for intermediate complexity
  - Performance measurement utilities
  - Debug output helpers
- Provide example usage in documentation
- Include comments explaining each section

**Success Criteria:**
- Template reduces test boilerplate by 50%
- Examples are clear and reusable
- Documentation helps contributors adopt the template

---

## [Docs] Write intermediate challenge strategy guide

**Description:**
Help contributors understand the complexity jump from beginner to intermediate challenges.

**Tasks:**
- Create `docs/intermediate-challenge-guide.md` covering:
  - Architectural patterns for stateful contracts
  - When to use nested storage structures
  - Authorization patterns for multiple parties
  - Testing multi-actor scenarios
  - Performance considerations at intermediate scale
  - Common security pitfalls and how to avoid them
- Include decision tree for choosing storage patterns
- Provide refactoring examples from beginner to intermediate
- Link to relevant Soroban documentation
- Add real examples from PLEarn challenges

**Success Criteria:**
- Guide helps contributors design intermediate challenges
- Examples are grounded in real PLEarn challenges
- Document includes security checklist

---

## Phase 4: Advanced Challenges (Issues 21-26)

---

## [Challenge] Implement 01-staking-contract with rewards

**Description:**
Complete the advanced staking contract with time-based reward calculations and yield mechanics.

**Tasks:**
- Expand `challenges/advanced/01-staking-contract/src/lib.rs` with:
  - Staking struct (amount, start_ledger, user)
  - Reward calculation logic (1% per 100 ledgers)
  - Compound rewards option
  - Minimum stake amount
  - Slashing mechanism (optional)
- Write 20+ comprehensive tests:
  - Staking locks tokens
  - Rewards accrue correctly over time
  - Unstaking returns principal + rewards
  - Multiple stakes per user
  - Reward precision with large numbers
  - Minimum stake enforcement
  - Edge cases (unstake before reward period, max rewards)
  - Ledger-based time advancement in tests
- Add benchmarks for common operations
- Document reward formula and assumptions

**Success Criteria:**
- Reward calculations are mathematically correct
- No rounding errors cause fund loss
- Multiple stakes are handled correctly

---

## [Challenge] Implement 02-multisig-wallet with approval workflows

**Description:**
Complete the advanced multisig wallet supporting M-of-N approvals and transaction execution.

**Tasks:**
- Expand `challenges/advanced/02-multisig-wallet/src/lib.rs` with:
  - Multisig struct (required_signatures, signers, pending_tx)
  - Transaction proposal and tracking
  - Approval voting among signers
  - Transaction execution once threshold met
  - Transaction cancellation
  - Signer management (add/remove signers)
- Write 25+ tests covering:
  - Creating transactions
  - Signers cannot sign twice
  - Execution only with M approvals
  - Non-signers cannot approve
  - Transaction state transitions
  - Fund transfers on execution
  - Event emission on key actions
  - Concurrent transaction handling
  - Edge cases (0-sig required, N+1 signers required)
- Add benchmarks for approval voting
- Document security considerations

**Success Criteria:**
- Multisig logic prevents unauthorized execution
- No approval loss or duplication
- Signer set changes are atomic

---

## [Challenge] Create 03-order-book-dex challenge

**Description:**
Build a decentralized exchange (DEX) with an order book model supporting limit orders.

**Tasks:**
- Create `challenges/advanced/03-order-book-dex/` directory
- INSTRUCTIONS.md with requirements:
  - `create_order(trading_pair: (Address, Address), side: Side, price: i128, amount: i128) -> u64` — returns order ID
  - `cancel_order(order_id: u64)`
  - `get_order_status(order_id: u64) -> OrderStatus`
  - Order matching when prices cross
  - Event emission on fills
- Implement starter code with:
  - Order struct (id, pair, side, price, amount, status)
  - Order book for each trading pair
  - TODO stubs for core functions
- Write 20+ tests:
  - Creating buy and sell orders
  - Orders don't match when prices don't cross
  - Orders match and partially fill correctly
  - Remaining amount after partial fill
  - Canceling orders removes from book
  - Multiple trading pairs coexist
  - Price precision and rounding
  - Performance with large order book
  - Event correctness

**Success Criteria:**
- Order matching logic is correct
- No double-fills or partial fills
- Performance is acceptable for 100+ orders

---

## [Challenge] Create 04-governance-dao challenge

**Description:**
Build a simple DAO (Decentralized Autonomous Organization) with treasury and governance voting.

**Tasks:**
- Create `challenges/advanced/04-governance-dao/` directory
- INSTRUCTIONS.md with requirements:
  - `create_proposal(title: String, description: String, action: Action) -> u32` — returns proposal ID
  - `vote(voter: Address, proposal_id: u32, vote: Vote)`
  - `execute_proposal(proposal_id: u32)` — if approved
  - `get_treasury_balance() -> i128`
  - Fund distribution proposals
- Implement starter code with:
  - Proposal struct (id, title, creator, votes_for/against, executed, deadline)
  - Voting participation tracking
  - Action enum (TransferFunds, ChangeParameter, etc.)
  - TODO stubs
- Write 25+ tests:
  - Proposals can only be created by members
  - Voting follows quorum requirements
  - Proposals execute only if approved
  - Treasury transfers happen correctly
  - Vote delegation (optional)
  - Parameter changes are atomic
  - Proposal timeouts
  - Multiple concurrent proposals

**Success Criteria:**
- Voting quorum is enforced
- Only approved proposals execute
- Treasury remains solvent

---

## [Challenge] Create 05-cross-contract-framework challenge

**Description:**
Build a framework showing best practices for complex cross-contract interactions and composability.

**Tasks:**
- Create `challenges/advanced/05-cross-contract-framework/` directory
- INSTRUCTIONS.md with requirements:
  - Multiple contracts that interact (Core, Token, Reward, Governance)
  - Standardized contract interfaces
  - Safe cross-contract error handling
  - State synchronization patterns
  - Atomic operations across contracts (if possible)
- Implement starter code with:
  - Contract interface definitions
  - Error handling wrappers
  - TODO stubs for orchestration logic
- Write 20+ integration tests:
  - Multi-contract workflows
  - Error propagation and handling
  - State consistency across contracts
  - Performance of orchestration
  - Reentrancy prevention (if applicable)
  - Contract upgrade handling (if applicable)

**Success Criteria:**
- Cross-contract calls are reliable
- Error handling is robust
- State remains consistent

---

## [Challenge] Create comprehensive advanced test patterns guide

**Description:**
Document advanced testing patterns and best practices for complex contracts.

**Tasks:**
- Create `docs/advanced-testing-guide.md` covering:
  - Property-based testing for contracts
  - Simulation-based testing for complex state
  - Performance benchmarking frameworks
  - Stress testing for scalability
  - Fuzz testing with randomized inputs
  - Integration test orchestration
  - Contract upgrade testing
- Include examples from PLEarn advanced challenges
- Provide reusable test macros and helpers
- Document debugging techniques for complex failures
- Link to advanced Soroban testing tools

**Success Criteria:**
- Guide covers patterns used in advanced challenges
- Examples are production-ready
- Contributors can apply patterns to new challenges

---

## Phase 5: Community & Infrastructure (Issues 27-30)

---

## [Docs] Create challenge template and contributor starter kit

**Description:**
Lower the barrier for contributors to add new challenges by providing a complete, tested template.

**Tasks:**
- Create `templates/challenge-template/` with:
  - `INSTRUCTIONS.md` with all required sections
  - `Cargo.toml` with correct dependencies
  - `src/lib.rs` with contract skeleton and TODO comments
  - `tests/test.rs` with test structure and examples
- Create `docs/challenge-creator-guide.md` with:
  - Step-by-step process for creating a challenge
  - Checklist before submitting PR
  - How to test the challenge locally
  - Common mistakes and how to avoid them
  - Naming conventions and structure
- Provide example walkthrough using the template
- Document difficulty rating criteria

**Success Criteria:**
- New contributor can create a challenge in under 1 hour
- Template enforces consistency
- Checklist catches most errors

---

## [Infra] Create GitHub issue templates and contributing guidelines

**Description:**
Streamline the contribution process with clear issue templates and guidelines.

**Tasks:**
- Create `.github/ISSUE_TEMPLATE/challenge.md` with fields for:
  - Challenge difficulty level
  - Objective and requirements
  - Success criteria
  - Estimated complexity
- Create `.github/ISSUE_TEMPLATE/bug.md` with:
  - Affected component (challenge, script, docs)
  - Steps to reproduce
  - Expected vs actual behavior
  - Environment details (OS, Rust version)
- Create `.github/PULL_REQUEST_TEMPLATE.md` with:
  - Description of changes
  - Type (challenge, bugfix, docs, infra)
  - Tests added or updated
  - Breaking changes (if any)
- Update `CONTRIBUTING.md` with:
  - Contribution types (challenges, fixes, docs, reviews)
  - Code style guide (clippy, fmt, naming)
  - Commit message conventions
  - PR review process

**Success Criteria:**
- Templates are visible when creating issues/PRs
- Guidelines are clear and actionable
- Contribution process is streamlined

---

## [Infra] Create monitoring and analytics dashboard

**Description:**
Track project health and contributor activity to understand where to focus efforts.

**Tasks:**
- Create `scripts/analytics.sh` to generate:
  - Challenge completion rates (if applicable)
  - Test coverage per challenge
  - Build times and trends
  - Code quality metrics (clippy warnings, fmt issues)
  - Contributor activity (commits, PRs, reviews)
- Generate weekly report to `docs/analytics/`
- Visualize trends in README (badges, charts)
- Document how to run analytics locally
- Set up GitHub Actions to run analytics on schedule

**Success Criteria:**
- Analytics provide actionable insights
- Reports are generated reliably
- Trends are visible over time

---

## [Docs] Create learning path and progression roadmap

**Description:**
Help learners understand the recommended progression through challenges and learning objectives at each stage.

**Tasks:**
- Create `docs/learning-path.md` with:
  - Recommended order: Beginner → Intermediate → Advanced
  - Learning objectives per tier
  - Estimated time to complete each challenge
  - Prerequisites and co-requisites
  - Difficulty progression graph
  - Real-world contract parallels
- Create `docs/skill-matrix.md` showing:
  - Skills taught by each challenge
  - Skill dependencies
  - How challenges build on each other
  - Advanced topics introduced
- Add progress tracker template for learners
- Include resources for deeper learning at each level
- Document how to adapt the path for different learning styles

**Success Criteria:**
- New learners can pick a starting challenge confidently
- Progression is logical and builds skills incrementally
- Resources are actionable and tested

---

## Summary

This roadmap encompasses:
- **Phase 1** (6 issues): Infrastructure, CI/CD, documentation, and tooling
- **Phase 2** (6 issues): Beginner challenges (03-05) and test expansion
- **Phase 3** (8 issues): Intermediate challenges (03-06) with sophisticated patterns
- **Phase 4** (6 issues): Advanced challenges (03-05) with production-like complexity
- **Phase 5** (4 issues): Community, templates, and learning infrastructure

**Total: 30 GitHub issues** covering testing, documentation, contract development, infrastructure, and community building.

All issues include:
- Clear acceptance criteria
- Specific, actionable tasks
- Success metrics
- Estimated complexity levels
- Cross-references to related work

Contributors can pick issues at their skill level and work independently or collaboratively.
