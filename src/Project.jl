module Project

using DataStructures

include("bank.jl")
include("loan.jl")
include("event.jl")
include("handle_event.jl")
include("simulation.jl")

export Bank, create_bank
export Loan, BulletLoan, create_loan
export Event, AbstractEvent, EventGrantClientLoan, EventRepaymentClientLoan, EventGrantBankLoan, EventRepaymentBankLoan, EventRepaymentDeposit, EventRequestClientLoan, EventRequestBankLoan
export Simulation, create_simulation, schedule_event!, execute_event!, get_event_id!, get_bank_id!, get_loan_id!, run!
@info "Project module loaded"
end
