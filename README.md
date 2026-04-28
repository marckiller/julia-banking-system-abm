# julia-banking-system-abm

A minimal agent-based banking system simulator written in Julia.

The model focuses on banks, reserve constraints, stochastic client loan/deposit flows, and interbank lending. It is inspired by zero-intelligence models: clients are not modeled as strategic agents, but as an exogenous stream of loan requests and deposit inflows.

The goal is to study how non-trivial banking-system dynamics can emerge from simple balance-sheet rules, liquidity constraints, and decentralized interbank funding.

## Demo

A fixed demo scenario is available in:

```bash
experiments/demo/
```

Run it with:

```bash
julia --project=. experiments/demo/run.jl
```

The demo writes metrics, event logs, and plots to:

```bash
results/demo/
```

The current demo shows a **liquidity-stressed but non-collapsing banking system**:

- credit demand is only partially satisfied,
- loans are rejected because of both credit risk and liquidity constraints,
- the interbank market becomes heavily used,
- most deposits are still repaid,
- banks become heterogeneous despite identical initial reserve allocation.

The demo is intentionally configured with tight liquidity conditions. The goal is not to reproduce real-world banking regulation, but to make the model mechanisms visible in a short simulation.

## Example demo results

In the current fixed demo run:

| Metric | Value |
|---|---:|
| Client loan requests | 8,435 |
| Granted client loans | 3,664 |
| Rejected client loans | 4,771 |
| Requested loan volume | 4.40B |
| Granted loan volume | 1.77B |
| Rejected loan volume | 2.62B |
| Loan acceptance rate | 43.4% |
| Loan volume acceptance rate | 40.3% |
| Interbank loans granted | 2,051 |
| Interbank volume | 988.5M |
| Interbank repayment rate | 90.6% |
| Deposit repayment rate | 99.55% |
| Unpaid matured deposits | 2.12M |

Generated plots include:

- system reserves over time,
- bank-level reserve trajectories,
- rejected loan reasons,
- loan acceptance versus liquidity buffer,
- interbank lending matrix,
- loan repayment/default outcomes,
- aggregate balance-sheet snapshot.

## Decentralization efficiency experiment

The repository also contains an experiment on `decentralization_efficiency`.

The idea is to evaluate how effectively a decentralized interbank market reallocates liquidity across banks. In a perfectly coordinated system, liquidity could be allocated where it is needed most. In this model, banks only interact through local borrowing attempts and lending constraints.

The experiment asks:

> How much useful credit activity can the system support when liquidity is fragmented across banks and redistributed only through decentralized interbank lending?

Results are written under:

```bash
results/
```

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

Run the demo:

```bash
julia --project=. experiments/demo/run.jl
```

Outputs will be saved under:

```bash
results/demo/
```

## Why this project exists

This project is a small experimental sandbox for studying banking-system dynamics from the bottom up.

It is not intended to be a calibrated macro-financial model. Instead, it asks a narrower question:

> How much structure can emerge from simple balance-sheet rules, random client demand, reserve constraints, and interbank liquidity redistribution?

This makes the model useful for exploring mechanisms such as credit rationing, liquidity stress, interbank dependence, repayment failures, and simple default cascades in a controlled toy environment.

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
- complex strategic bank behavior.

## License

Apache License 2.0