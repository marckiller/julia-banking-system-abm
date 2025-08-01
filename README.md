# julia-banking-system-abm
> ⚠️ **Development Version**  
> This project is in active development. Assumptions, implementations, and architecture are subject to change as the model evolves.
---
## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/marckiller/julia-banking-system-abm.git
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
julia --project=. experiments/demo/run.jl
```
This demo runs a full simulation of a small multi-bank system using predefined parameters from the config.jl file. Feel free to adjust any parameters to suit your own experimental needs or scenarios.

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
- **Loans and deposits policy** Banks always accept client deposits and always agree to issue interbank loans if they have sufficient liquidity. A bank will grant a client loan only if the expected value of the loan — computed as (1 - P_default) × repayment_amount — exceeds the principal of a loan plus any cost of required interbank borrowing.

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
## More Detailed Simulation Mechanism

### Event-Based Architecture

The simulation operates in an event-driven manner. Each event is defined by a unique event_id, a trigger_event_id (used only for analyzing cascades of causally related events), a simulation time, and a set of event-specific parameters. Time in the simulation advances by processing events in a priority queue, ordered chronologically.

A simulation run begins by pre-generating a scenario—typically a stream of random client requests for loans and deposits—and pushing those events into the event queue. Each event type (e.g., loan request, loan grant, loan repayment) has a dedicated execution method implemented in the event handler. Executing an event may trigger monetary flows, update balance sheets (assets and liabilities), and schedule future events. For instance, EventGrantClientLoan automatically schedules a corresponding EventRepaymentClientLoan at the maturity date of the loan.

Once the queue is empty, the simulation ends. The main output consists of:
-	a vector of executed events, from which metrics such as loan request acceptance rates can be computed,
-	a vector of loans, allowing analysis of default rates and repayment behavior,
-	a time series log of each bank’s financial state, including reserves, liabilities, and loan assets.

These outputs enable post-simulation analysis of the system’s performance, risk exposure, and liquidity dynamics.

### Loan System

All loans in the simulation are implemented using a single unified structure: BulletLoan. This type of loan is repaid in full—principal plus interest—at maturity, with no intermediate payments. The same data structure is used to represent three different economic relationships:
- Client loans, where a bank lends money to a client,
-	Client deposits, interpreted as loans from clients to banks,
-	Interbank loans, where one bank lends to another to cover liquidity needs.

This design choice simplifies the logic by treating all cash flow commitments symmetrically, regardless of direction. Only the roles of lender and borrower change depending on the context.

