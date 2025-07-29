const RNG_SEED = 42

# === Banks ===
const NUM_BANKS = 5
const TOTAL_INITIAL_RESERVES = 1_000_000_000
const MIN_INITIAL_RESERVES = 1_000_000
const MIN_RESERVES_FACTOR = 0.3
const R_CLIENT_LOAN = 0.1
const R_BANK_LOAN = 0.05
const R_DEPOSIT = 0.02

# === Client Loans ===
const CLIENT_LOAN_AMOUNT_RANGE = (5_000_000, 25_000_000)
const CLIENT_LOAN_TERMS = [7, 14, 30, 60, 90]
const CLIENT_LOAN_DEFAULT_PROB_RANGE = (0.01, 0.5)
const CLIENT_LOAN_ARRIVAL_RATE = 5.0# lambda (avg per day)

# === Deposits ===
const CLIENT_DEPOSIT_AMOUNT_RANGE = (5_000_000, 50_000_000)
const CLIENT_DEPOSIT_TERMS = [30, 60, 90]
const CLIENT_DEPOSIT_ARRIVAL_RATE = 4.0# lambda (avg per day)

# === Interbank Loans ===
const INTERBANK_LOAN_TERM = 1

# === Simulation Horizon ===
const SIMULATION_DURATION_DAYS = 360