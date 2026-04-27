# Decentralization Efficiency Experiment

This experiment studies how splitting the same total reserve base across a larger number of banks affects credit availability, liquidity stress, and system-level outcomes in a simplified zero-intelligence banking model.

The goal is to make one mechanism visible: the trade-off between centralized liquidity pooling and decentralized balance-sheet constraints.

## Research Question

How does the number of banks in the system affect liquidity and credit allocation when the total amount of initial reserves is held constant?

More concretely, the experiment compares systems where:

- one bank holds the entire initial reserve base,
- the same reserve base is split evenly across multiple banks,
- client loan and deposit demand arrives stochastically,
- banks follow simple rule-based decisions,
- banks may use the interbank market when they lack enough liquidity to satisfy a client loan request.

## Model Assumptions

This experiment uses the core `BankSim` model with rule-based bank behavior.

The model is intentionally zero-intelligence:

- client demand is represented by exogenous stochastic loan and deposit requests,
- banks follow deterministic balance-sheet rules,
- bank decisions use current reserves, liabilities, interest rates, and default probabilities,
- interbank lending is used as a short-term liquidity mechanism,
- defaults are stochastic and based on configured probabilities.

## Experimental Design

The experiment varies two main parameters:

- `NUM_BANKS`: number of banks in the system,
- `MIN_RESERVES_FACTOR`: minimum reserve requirement as a fraction of liabilities.

The total initial reserve base is fixed. For each value of `NUM_BANKS`, the same total reserve amount is split evenly across banks.

Example:

```text
TOTAL_INITIAL_RESERVES = 1_000_000_000

NUM_BANKS = 1
bank reserves = [1_000_000_000]

NUM_BANKS = 5
bank reserves = [200_000_000, 200_000_000, 200_000_000, 200_000_000, 200_000_000]

NUM_BANKS = 10
bank reserves = [100_000_000, ..., 100_000_000]
```

This creates two competing effects:

- **Liquidity pooling**: fewer banks means reserves are concentrated in fewer balance sheets, making large loan requests easier to satisfy directly.
- **Interbank coordination**: more banks creates local liquidity shortages and surpluses, allowing the interbank market to redistribute reserves when possible.

The experiment shows how decentralization changes credit access, interbank borrowing, and reserve-constrained stability.

## Metrics

Each simulation run produces a replayable event log in memory. Metrics are computed from that log and aggregated by `NUM_BANKS` and `MIN_RESERVES_FACTOR`.

| Metric | Meaning |
| --- | --- |
| `loan_volume_acceptance_rate` | Share of requested client loan principal that was granted |
| `deposit_volume_repay_rate` | Share of matured deposit repayment value paid on time |
| `interbank_dependency_rate` | Granted interbank loans divided by granted client loans |
| `liquidity_stress_volume_rate` | Share of requested client loan principal rejected |
| `bank_net_growth_ratio` | Final total bank net worth divided by initial total bank net worth |
| `liquidity_score` | Composite visual score combining credit availability, deposit repayment, interbank repayment, loan stress, and bank net worth growth |

The composite liquidity score is a compact visual summary. Individual metrics should be inspected alongside it.

## Output Files

The experiment writes:

```text
results/decentralization_efficiency_demo/
├── metrics.csv
├── runs.csv
├── summary.csv
└── plots/
```

`metrics.csv` contains one row per simulation run. `runs.csv` stores seeds and parameter values. `summary.csv` averages metrics by `NUM_BANKS` and `MIN_RESERVES_FACTOR`. Full event logs are optional debug output.

## Results

The demo run uses:

```text
replications = 10
NUM_BANKS = 1:10
MIN_RESERVES_FACTOR = [0.1, 0.3, 0.5, 0.7, 0.9]
simulation_duration_days = 720
client_loan_requests_per_day = 20.0
client_deposit_requests_per_day = 5.0
```

### Interbank Dependency

![Interbank dependency rate](../../results/decentralization_efficiency_demo/plots/heatmap_interbank_dependency_rate.svg)

Splitting the reserve base across more banks increases reliance on the interbank market. The effect grows quickly from one to five banks and then begins to flatten as the number of banks approaches ten.

### Deposit Repayment

![Deposit repayment rate](../../results/decentralization_efficiency_demo/plots/heatmap_deposit_volume_repay_rate.svg)

Deposit repayment remains high overall, but repayment quality falls as the number of banks increases under low reserve requirements. Higher reserve factors reduce this deposit-side stress.

### Liquidity Score

![Liquidity score](../../results/decentralization_efficiency_demo/plots/heatmap_liquidity_score.svg)

The composite score is highest in the centralized setting and declines as reserves are split across more banks, especially under low reserve requirements. In this zero-intelligence setup, centralized liquidity pooling dominates the coordination benefit of a larger interbank market.

### Loan Volume Acceptance

![Loan volume acceptance rate](../../results/decentralization_efficiency_demo/plots/heatmap_loan_volume_acceptance_rate.svg)

Loan volume acceptance is relatively stable across the grid. The main effect of decentralization appears in liquidity coordination and repayment stress rather than in aggregate loan volume granted.

## How To Run

From the repository root:

```bash
julia --project=. -e 'include("experiments/decentralization_efficiency/run.jl"); run_experiment(results_dir="results/decentralization_efficiency_demo", averaging_n=10, number_of_banks=collect(1:10), min_reserves_factors=[0.1,0.3,0.5,0.7,0.9], simulation_duration_days=720, client_loan_requests_per_day=20.0, client_deposit_requests_per_day=5.0)'
```

```bash
julia --project=. experiments/decentralization_efficiency/plot.jl results/decentralization_efficiency_demo
```

## Reproducibility

Each replication uses a deterministic aggregate demand scenario generated from `scenario_seed`. Each market configuration receives the same aggregate demand stream, with requests randomly routed to banks using a recorded `run_seed`.

The output files retain both seeds:

```text
runs.csv:
run_id, replication_id, scenario_seed, run_seed, NUM_BANKS, MIN_RESERVES_FACTOR
```