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

export Bank, create_bank
export Loan, BulletLoan, create_loan
export Event, AbstractEvent, EventGrantClientLoan, EventRepaymentClientLoan, EventGrantBankLoan, EventRepaymentBankLoan, EventRepaymentDeposit, EventRequestClientLoan, EventRequestBankLoan, EventRequestClientDeposit
export Simulation, create_simulation, schedule_event!, execute_event!, get_event_id!, get_bank_id!, get_loan_id!, run!, log_bank_states!, add_bank!, run_simulation!
@info "Project module loaded"
end
