const RNG_SEED = 40

# === Banks ===
const NUM_BANKS = 10
const TOTAL_INITIAL_RESERVES = 1_000_000_000

# === Parameter space ===
const V_MIN_RESERVES_FACTOR = [0.1,0.2,0.3, 0.4, 0.5, 0.6, 0.7, 0.8]
const V_R_CLIENT_LOAN = [0.08, 0.1, 0.12, 0.14, 0.16, 0.18, 0.2]
const V_R_DEPOSIT = [0.01, 0.02, 0.03, 0.04]
const V_R_BANK_LOAN =  [0.04, 0.05, 0.06, 0.07]

# === Client Loans ===
const CLIENT_LOAN_AMOUNT_RANGE = (50_000, 1_000_000)
const CLIENT_LOAN_TERMS = [30, 90, 180, 360, 720, 1080]
const CLIENT_LOAN_DEFAULT_PROB_RANGE = (0.01, 0.2)
const CLIENT_LOAN_ARRIVAL_RATE = 40.0

# === Deposits ===
const CLIENT_DEPOSIT_AMOUNT_RANGE = (10_000, 1_00_000)
const CLIENT_DEPOSIT_TERMS = [30, 90, 180, 360]
const CLIENT_DEPOSIT_ARRIVAL_RATE = 100.0

# === Interbank Loans ===
const INTERBANK_LOAN_TERM = 1

# === Simulation Horizon ===
const SIMULATION_DURATION_DAYS = 3600