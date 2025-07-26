mutable struct Base
    id::Int
    reserves::Int
    min_reserves::Int

    total_liabilities::Int #deposits and bank loans
    total_loan_assets::Int #client loans and bank loans

    R_client_loan::Int
    R_bank_loan::Int
    R_deposit::Int
end

function Bank(id::Int, reserves::Int, min_reserves::Int, R_client_loan::Int, R_bank_loan::Int, R_deposit::Int)
    return Base(id, reserves, min_reserves,0,0, R_client_loan, R_bank_loan, R_deposit)
end