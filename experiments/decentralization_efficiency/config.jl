const RNG_SEED = 42
const SCENARIO_SEED_BASE = 10_000
const RUN_SEED_BASE = 100_000
const AVERAGING_N = 8

const NUMBER_OF_BANKS = collect(1:10)
const MIN_RESERVES_FACTORS = [0.1, 0.3, 0.5, 0.7, 0.9]
const RESULTS_DIR = "results/decentralization_efficiency"
const EVENTS_DIR = joinpath(RESULTS_DIR, "events")
const SAVE_EVENTS = false
const SAVE_EVENT_RUN_IDS = Int[]

# === Banks ===
const TOTAL_INITIAL_RESERVES = 300_000_000
const MIN_RESERVES_FACTOR = 0.6
const R_CLIENT_LOAN = 0.2
const R_BANK_LOAN = 0.05
const R_DEPOSIT = 0.01

# === Client Loans ===
const CLIENT_LOAN_AMOUNT_RANGE = (50_000, 1_000_000)
const CLIENT_LOAN_TERMS = [90, 180, 360]
const CLIENT_LOAN_DEFAULT_PROB_RANGE = (0.005, 0.06)
const CLIENT_LOAN_REQUESTS_PER_DAY = 25.0

# === Deposits ===
const CLIENT_DEPOSIT_AMOUNT_RANGE = (10_000, 1_00_000)
const CLIENT_DEPOSIT_TERMS = [30, 90]
const CLIENT_DEPOSIT_REQUESTS_PER_DAY = 5.0

# === Interbank Loans ===
const INTERBANK_LOAN_TERM = 1

# === Simulation Horizon ===
const SIMULATION_DURATION_DAYS = 720
const ANALYSIS_START_DAY = 180
const ANALYSIS_END_DAY = SIMULATION_DURATION_DAYS
