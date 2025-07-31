# julia-banking-system-abm
> ⚠️ **Development Version**  
> This project is in active development. Assumptions, implementations, and architecture are subject to change as the model evolves.
---
## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourname/julia-banking-system-abm.git
cd julia-banking-system-abm
```

### 2. Launch Julia with the project environment

```bash
julia --project=.
```
This will install all packages listed in Project.toml.

### 3. Instantiate dependencies

```bash
using Pkg
Pkg.instantiate()
```

### 4. Run an experiment

```bash
julia --project=. experiments/liquidity_optimization/demo.jl
```

## Project motivation

This project aims to create the simplest possible agent-based simulation of a banking system that includes:

- Consumer loan issuance,
- Consumer deposit handling,
- Interbank lending as a liquidity adjustment mechanism.
  
The model is loosely inspired by zero-intelligence agent models in financial market microstructure. In particular, clients are not implemented as agents. Instead, the banking system is exposed to a stream of exogenous loan and deposit requests generated stochastically. These requests represent aggregate client behavior but do not originate from entities with goals, constraints, or budgets. This abstraction removes individual-level dynamics and frames client activity as background noise — enabling the simulation to focus purely on the banking system’s structural response to demand shocks.

The goal is to explore — through simulation — the emergence of stabilizing and destabilizing dynamics in such a system, particularly under constraints such as reserve requirements and limited interbank liquidity.

## Core Assumptions

- **Agents**: Only banks are modeled explicitly. Clients are implicit and generate stochastic events.
- **Revenue Sources**: Banks can only earn via consumer loans and interbank loans.
- **Randomness**: Loan and deposit requests arrive randomly based on configured rate parameters.
- **Bullet Loans Only**: All loans are repaid once at maturity (principal + interest).
- **Perfect Default Estimation**: Banks are given the borrower's probability of default (`P_default`) directly. No estimation is performed.
- **Hard Reserve Constraint**: Each bank is required to maintain a reserve buffer proportional to its liabilities.
- **Interbank Lending**: If a bank lacks sufficient reserves to grant a consumer loan, it selects another bank at random and attempts to borrow the needed funds via a one-day interbank loan.

## Project Structure

```
/julia-banking-system-abm
├── src/
│   ├── BankSim.jl              # Main module – imports all components
│   ├── bank.jl                 # Bank structure and logic
│   ├── loan.jl                 # Loan definition (deposits are also loans)
│   ├── event.jl                # Event types used in the system
│   ├── handle_event.jl         # Logic for handling each type of event
│   ├── simulation_io.jl        # Save/load events, loans, and bank states
│   ├── simulation.jl           # Global simulation state
│   └── utils.jl                # Helper functions
├── experiments/                # Experimental playgrounds
├── LICENSE
├── .gitignore
├── Project.toml
└── README.md
```
## Getting 

