module BankSim

using DataStructures
using DataFrames
using CSV
using Random

include("bank.jl")
include("loan.jl")
include("event.jl")
include("utils.jl")
include("simulation.jl")
include("handle_event.jl")
include("simulation_io.jl")

export Bank, create_bank
export Loan, BulletLoan, create_loan
export Event, AbstractEvent, EventGrantClientLoan, EventRepaymentClientLoan, EventGrantBankLoan, EventRepaymentBankLoan, EventRepaymentDeposit, EventRequestClientLoan, EventRequestBankLoan, EventRequestClientDeposit, EventGrantClientDeposit
export Simulation, create_simulation, schedule_event!, execute_event!, get_event_id!, get_bank_id!, get_loan_id!, run!, log_bank_states!, add_bank!, run_simulation!
export flatten_event, reconstruct_event, keys_union, flattened_events_to_dataframe, load_events_from_csv, save_events_to_csv, load_events_from_csv, save_loans_to_csv, load_loans_from_csv, save_banks_states_to_csv, load_banks_states_from_csv
@info "Project module loaded"
end
