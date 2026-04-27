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

These assumptions keep the experiment focused on structural liquidity effects.

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

Each simulation run records raw event counts and balance-sheet outcomes. The main derived metrics are:

| Metric | Meaning |
| --- | --- |
| `loan_acceptance_rate` | Share of client loan requests that were granted |
| `deposit_default_rate` | Share of client deposits that defaulted at repayment |
| `interbank_default_rate` | Share of interbank loans that defaulted |
| `interbank_loan_count` | Number of granted interbank loans |
| `bank_net_growth_ratio` | Final total bank net worth divided by initial total bank net worth |
| `liquidity_score` | Composite score combining credit availability, deposit safety, interbank stability, and system net worth |

The composite liquidity score is a visual summary. Individual metrics should be inspected alongside it.

## Expected Outputs

The analysis pipeline produces:

- raw simulation results as CSV,
- aggregated summary tables,
- heatmaps over `NUM_BANKS` and `MIN_RESERVES_FACTOR`,
- line plots showing how metrics change with the number of banks,
- selected charts embedded in this README.

Planned visual outputs:

```text
results/decentralization_efficiency/plots/
├── heatmap_liquidity_score.png
├── heatmap_loan_acceptance_rate.png
├── heatmap_bank_net_growth_ratio.png
├── heatmap_interbank_loan_count.png
└── loan_acceptance_by_num_banks.png
```

## Example Result Summary

Embed the main generated figures here:

```markdown
![Liquidity score heatmap](../../results/decentralization_efficiency/plots/heatmap_liquidity_score.png)

![Loan acceptance heatmap](../../results/decentralization_efficiency/plots/heatmap_loan_acceptance_rate.png)
```

Interpretation should focus on the visible trade-off:

- whether centralized liquidity improves loan acceptance,
- whether decentralization increases reliance on interbank lending,
- whether stricter reserve requirements reduce defaults at the cost of credit availability,
- whether there is a robust middle region where liquidity and stability are both acceptable.

## How To Run

From the repository root:

```bash
julia --project=. experiments/decentralization_efficiency/run.jl
julia --project=. experiments/decentralization_efficiency/plot.jl
```

The implementation is being refactored toward a reproducible experiment pipeline:

- deterministic runs from explicit seeds,
- controlled scenario generation,
- one output directory per experiment run,
- safe metric calculations,
- plots generated directly from saved result files.

## Refactoring Targets

1. Use explicit scenario seeds for all runs.
2. Separate scenario generation from simulation execution.
3. Compare parameter settings on shared demand scenarios.
4. Move metric calculation into a dedicated `metrics.jl`.
5. Add safe ratio helpers for zero-denominator cases.
6. Generate summary tables and plots from saved CSV files.
7. Add experiment-level tests for reproducibility and metric validity.
8. Embed final result figures in this README.
