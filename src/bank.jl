mutable struct Bank
    id::Int
    reserves::Int
    min_reserves::Float64

    total_liabilities::Int #deposits and bank loans
    total_loan_assets::Int #client loans and bank loans

    R_client_loan::Float64  
    R_bank_loan::Float64  
    R_deposit::Float64

end

function create_bank(id::Int, reserves::Int, min_reserves::Float64, R_client_loan::Float64, R_bank_loan::Float64, R_deposit::Float64)
    return Bank(id, reserves, min_reserves, 0, 0, R_client_loan, R_bank_loan, R_deposit)
end