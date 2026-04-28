# julia-banking-system-abm

A minimal agent-based banking system simulator written in Julia.

The model focuses on banks, reserve/liquidity constraints, stochastic client loan/deposit flows, and interbank lending. It is inspired by zero-intelligence models: clients are not modeled as strategic agents, but as an exogenous stream of loan requests and deposit inflows.

## Contents

- [Quick start](#quick-start)
- [Experiments](#experiments)
- [Model overview](#model-overview)
- [Core assumptions](#core-assumptions)
- [Current limitations](#current-limitations)
- [License](#license)

## Quick start

Clone the repository:

```bash
git clone https://github.com/marckiller/julia-banking-system-abm.git
cd julia-banking-system-abm
```

Instantiate the Julia environment:

```bash
julia --project=.
```

Then inside Julia:

```julia
using Pkg
Pkg.instantiate()
```

Run the main demo:

```bash
julia --project=. experiments/demo/run.jl
```

Demo outputs are saved under:

```bash
results/demo/
```

See [experiments/demo/README.md](experiments/demo/README.md) for the demo setup, output files, plots, and observed results.

## Experiments

Each experiment folder has its own README with the runnable command, generated outputs, and result figures. These pages are convenient to browse directly on GitHub:

- [Demo experiment](experiments/demo/README.md)
- [Decentralization efficiency experiment](experiments/decentralization_efficiency/README.md)

### Demo

A fixed simulation scenario showing a liquidity-stressed but non-collapsing banking system. It generates event logs, summary metrics, and plots for credit rationing, liquidity stress, interbank lending, repayment outcomes, and balance-sheet consistency.

Run:

```bash
julia --project=. experiments/demo/run.jl
```

Results:

```bash
results/demo/
```

Documentation: [experiments/demo/README.md](experiments/demo/README.md)

### Decentralization efficiency

An experiment measuring how effectively a decentralized interbank market reallocates fragmented liquidity across banks. It compares credit activity supported under decentralized liquidity redistribution.

Run:

```bash
julia --project=. experiments/decentralization_efficiency/run.jl
```

Results:

```bash
results/decentralization_efficiency/
```

Documentation: [experiments/decentralization_efficiency/README.md](experiments/decentralization_efficiency/README.md)

## Model overview

The simulation is event-driven.

A scenario generates random client loan requests and deposit inflows. Events are processed chronologically. Each event may update bank balance sheets, create new financial obligations, or schedule future repayment events.

The model includes three types of financial relationships:

1. client loans,
2. client deposits,
3. interbank loans.

All are represented as bullet-style obligations: repayment occurs once at maturity, with no intermediate payments. This keeps the accounting logic simple and makes all cash-flow commitments structurally comparable.

## Core assumptions

Only banks are modeled as explicit agents. Clients are implicit and generate stochastic loan/deposit events.

Banks earn income from client loans and interbank loans. A client loan is granted only if:

1. it has positive expected value under the given default probability,
2. the bank can fund it while satisfying its reserve/liquidity constraint.

If a bank lacks enough liquidity to grant a loan, it may try to borrow from another bank on the interbank market. Interbank lending therefore acts as a liquidity adjustment mechanism between banks.

The model currently assumes:

- stochastic client loan and deposit demand,
- bullet loans only,
- direct access to borrower default probability,
- hard reserve/liquidity constraints,
- simple interbank lending,
- no strategic clients,
- no central bank,
- no endogenous interest-rate formation,
- no capital adequacy regulation.

## Current limitations

This is a deliberately minimal model.

It does not yet include:

- strategic households or firms,
- a central bank,
- endogenous interest rates,
- regulatory capital,
- deposit insurance,
- macroeconomic feedback,
- learning behavior,
- strategic bank behavior.

The reserve/liquidity factor used in demo scenarios should be interpreted as a modeling constraint, not as a calibrated real-world reserve requirement.

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
