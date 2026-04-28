using DataFrames

function save_plot_index(output_dir::String, events::DataFrame)
    requested_count = event_count(events, "EventRequestClientLoan")
    granted_count = event_count(events, "EventGrantClientLoan")
    rejected_count = event_count(events, "EventRejectClientLoan")
    requested_volume = event_principal_sum(events, "EventRequestClientLoan")
    granted_volume = event_principal_sum(events, "EventGrantClientLoan")
    rejected_volume = event_principal_sum(events, "EventRejectClientLoan")

    rows = [
        "<!doctype html>",
        "<html><head><meta charset=\"utf-8\"><title>BankSim demo plots</title>",
        "<style>body{font-family:Arial,sans-serif;margin:32px;color:#111827;background:#fff}main{max-width:980px;margin:auto}section{margin:0 0 28px}img{max-width:100%;border:1px solid #e5e7eb;background:white}h1{font-size:24px}h2{font-size:16px;margin-bottom:10px}</style>",
        "</head><body><main><h1>BankSim Demo Plots</h1>",
        "<p>Shaded regions mark the settlement tail after new client requests stop.</p>",
        "<section><h2>Bank reserves over time</h2><img src=\"bank_reserves.svg\" alt=\"Bank reserves over time\"></section>",
        "<section><h2>System reserves over time</h2><img src=\"system_reserves.svg\" alt=\"System reserves over time\"></section>",
        "<section><h2>System liquidity buffer over time</h2><img src=\"system_liquidity_buffer.svg\" alt=\"System liquidity buffer over time\"></section>",
        "<section><h2>System balance sheet</h2><img src=\"system_balance_sheet.svg\" alt=\"System balance sheet\"></section>",
        "<section><h2>Client loan volume over time</h2><img src=\"client_loan_volume_over_time.svg\" alt=\"Client loan volume over time\"></section>",
        "<section><h2>Rolling client loan volume</h2><img src=\"rolling_client_loan_volume.svg\" alt=\"Rolling client loan volume\"></section>",
        "<p>Client loan requests: $(requested_count), granted: $(granted_count), rejected: $(rejected_count). Requested volume: $(format_bar_value(requested_volume, :money)), granted: $(format_bar_value(granted_volume, :money)), rejected: $(format_bar_value(rejected_volume, :money)).</p>",
        "<section><h2>Rejected client loans by reason</h2><img src=\"rejected_client_loans_by_reason.svg\" alt=\"Rejected client loans by reason\"></section>",
        "<section><h2>Rolling loan acceptance rate</h2><img src=\"rolling_loan_acceptance_rate.svg\" alt=\"Rolling loan acceptance rate\"></section>",
        "<section><h2>Rolling acceptance rate vs liquidity buffer</h2><img src=\"acceptance_vs_liquidity_buffer.svg\" alt=\"Rolling acceptance rate vs liquidity buffer\"></section>",
        "<section><h2>Client loan repayment outcomes by value</h2><img src=\"client_loan_repayment_value.svg\" alt=\"Client loan repayment outcomes by value\"></section>",
        "<section><h2>Interbank lending matrix</h2><img src=\"interbank_lending_matrix.svg\" alt=\"Interbank lending matrix\"></section>",
        "</main></body></html>"
    ]
    write(joinpath(output_dir, "index.html"), join(rows, "\n"))
end

function save_demo_plots(events::DataFrame, bank_states::DataFrame, output_dir::String)
    mkpath(output_dir)

    save_bank_reserves_plot(bank_states, joinpath(output_dir, "bank_reserves.svg"))
    save_system_reserves_plot(bank_states, joinpath(output_dir, "system_reserves.svg"))
    save_system_liquidity_buffer_plot(bank_states, joinpath(output_dir, "system_liquidity_buffer.svg"))
    save_balance_sheet_plot(events, bank_states, joinpath(output_dir, "system_balance_sheet.svg"))
    save_cumulative_principal_plot(
        events,
        ["EventRequestClientLoan", "EventGrantClientLoan", "EventRejectClientLoan"],
        ["requested", "granted", "rejected"],
        "Client loan volume over time",
        joinpath(output_dir, "client_loan_volume_over_time.svg")
    )
    save_rolling_loan_volume_plot(events, joinpath(output_dir, "rolling_client_loan_volume.svg"))
    save_rejection_reasons_plot(events, joinpath(output_dir, "rejected_client_loans_by_reason.svg"))
    save_rolling_acceptance_plot(events, joinpath(output_dir, "rolling_loan_acceptance_rate.svg"))
    save_acceptance_vs_buffer_plot(events, bank_states, joinpath(output_dir, "acceptance_vs_liquidity_buffer.svg"))
    save_client_loan_repayment_value_plot(events, joinpath(output_dir, "client_loan_repayment_value.svg"))
    save_interbank_matrix_plot(events, joinpath(output_dir, "interbank_lending_matrix.svg"))
    save_plot_index(output_dir, events)
end
