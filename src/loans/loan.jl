mutable struct Loan_simple
    principal::Int
    interest::Float64
    due_in::Int
    from::Int
    to::Int
end

function total_due(loan::Loan_simple)::Int
    return round(Int, loan.principal * (1 + loan.interest))
end

function update_due!(loan::Loan_simple)
    loan.due_in = max(loan.due_in - 1, 0)
end

function is_due(loan::Loan_simple)::Bool
    return loan.due_in == 0
end