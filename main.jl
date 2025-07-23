const SIM_PARAMS = Dict(
    :tick_length_days => 1,
    :simulation_duration_ticks => 365,
    
    :loan_request_rate => 5.0,
    :deposit_request_rate => 4.0,
    :loan_amount_distribution => () -> rand(1000:5000),
    :deposit_amount_distribution => () -> rand(1000:5000),
    :loan_default_probability_distribution => () -> rand(0.01:0.1),
    :loan_term_distribution => () -> rand(30:180)*SIM_PARAMS[:tick_length_days],

    :annual_credit_interest_rate => 0.08,
    :annual_deposit_interest_rate => 0.02,
    :min_acceptable_ev_margin => 1.00,

    :interbank_interest_rate => 0.04,
    :interbank_loan_term_days => 1,
    :interbank_match_strategy => :random)