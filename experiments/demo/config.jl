banks = [
    Dict(
        "id" => 1,
        "reserves" => 100_000_000,
        "min_reserves_factor" => 0.4,
        "r_client_loan" => 0.1,
        "r_bank_loan" => 0.05,
        "r_deposit" => 0.02
    ),
    Dict(
        "id" => 2,
        "reserves" => 150_000_000,
        "min_reserves_factor" => 0.3,
        "r_client_loan" => 0.12,
        "r_bank_loan" => 0.06,
        "r_deposit" => 0.03
    ),
    Dict(
        "id" => 3,
        "reserves" => 200_000_000,
        "min_reserves_factor" => 0.5,
        "r_client_loan" => 0.08,
        "r_bank_loan" => 0.04,
        "r_deposit" => 0.01
    ),
    Dict(
        "id" => 4,
        "reserves" => 120_000_000,
        "min_reserves_factor" => 0.35,
        "r_client_loan" => 0.11,
        "r_bank_loan" => 0.07,
        "r_deposit" => 0.025
    )
]

const RNG_SEED = 40

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
const SIMULATION_DURATION_DAYS = 10000