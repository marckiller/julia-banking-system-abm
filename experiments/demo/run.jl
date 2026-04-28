using CSV
using DataFrames
using Printf

include(joinpath(@__DIR__, "..", "decentralization_efficiency", "run.jl"))

const DEMO_RESULTS_DIR = "results/demo"
const DEMO_PLOTS_DIR = joinpath(DEMO_RESULTS_DIR, "plots")

const DEMO_NUM_BANKS = 5
const DEMO_MIN_RESERVES_FACTOR = 0.5
const DEMO_SCENARIO_SEED = 10_001
const DEMO_RUN_SEED = 150_501
const DEMO_DURATION_DAYS = 2000
const DEMO_CLIENT_LOAN_TERMS = [30, 90, 180, 360]
const DEMO_CLIENT_DEPOSIT_TERMS = [30, 90, 180]
const DEMO_CLIENT_LOAN_REQUESTS_PER_DAY = 10.0
const DEMO_CLIENT_DEPOSIT_REQUESTS_PER_DAY = 50.0

function svg_escape(value)
    text = string(value)
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    text = replace(text, "\"" => "&quot;")
    return text
end

function scale_value(value::Real, lo::Real, hi::Real, out_lo::Real, out_hi::Real)
    if lo == hi
        return (out_lo + out_hi) / 2
    end
    return out_lo + (Float64(value) - Float64(lo)) / (Float64(hi) - Float64(lo)) * (out_hi - out_lo)
end

function bank_net_worth(row)
    return Float64(row.reserves + row.total_loan_assets - row.total_liabilities)
end

function save_bank_reserves_plot(bank_states::DataFrame, output_path::String)
    colors = ["#2563eb", "#dc2626", "#16a34a", "#9333ea", "#ea580c", "#0891b2"]
    width = 920
    height = 420
    left = 78
    right = 26
    top = 48
    bottom = 64
    plot_w = width - left - right
    plot_h = height - top - bottom

    times = bank_states.time
    values = Float64.(bank_states.reserves)
    x_min, x_max = minimum(times), maximum(times)
    y_min, y_max = minimum(values), maximum(values)
    y_pad = max((y_max - y_min) * 0.08, 1.0)
    y_min -= y_pad
    y_max += y_pad

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">Bank reserves over time</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Reserves</text>"""
    ]

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(y_min, y_max; length = 5)
        y = scale_value(v, y_min, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(@sprintf("%.2e", v))</text>""")
    end

    for (idx, bank_id) in enumerate(sort(unique(bank_states.id)))
        bank_rows = sort(filter(row -> row.id == bank_id, bank_states), :time)
        points = String[]
        for row in eachrow(bank_rows)
            x = scale_value(row.time, x_min, x_max, left, left + plot_w)
            y = scale_value(row.reserves, y_min, y_max, top + plot_h, top)
            push!(points, @sprintf("%.2f,%.2f", x, y))
        end
        color = colors[mod1(idx, length(colors))]
        push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="$color" stroke-width="2"/>""")
        legend_x = left + 12 + (idx - 1) * 82
        push!(rows, """<rect x="$legend_x" y="$(height - 44)" width="10" height="10" fill="$color"/>""")
        push!(rows, """<text x="$(legend_x + 16)" y="$(height - 35)" font-family="Arial, sans-serif" font-size="11" fill="#374151">Bank $bank_id</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function cumulative_event_series(events::DataFrame, event_types::Vector{String})
    times = sort(unique(events.time))
    series = Dict{String, Vector{Int}}(event_type => Int[] for event_type in event_types)
    counts = Dict(event_type => 0 for event_type in event_types)

    for time in times
        today = filter(row -> row.time == time, events)
        for event_type in event_types
            counts[event_type] += count(==(event_type), today.event_type)
            push!(series[event_type], counts[event_type])
        end
    end

    return times, series
end

function save_cumulative_event_plot(events::DataFrame, event_types::Vector{String}, labels::Vector{String}, title::String, output_path::String)
    colors = ["#2563eb", "#dc2626", "#16a34a", "#9333ea", "#ea580c", "#0891b2"]
    width = 920
    height = 420
    left = 72
    right = 28
    top = 48
    bottom = 70
    plot_w = width - left - right
    plot_h = height - top - bottom

    times, series = cumulative_event_series(events, event_types)
    x_min, x_max = minimum(times), maximum(times)
    y_max = max(maximum(vcat(values(series)...)), 1)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">$(svg_escape(title))</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Cumulative events</text>"""
    ]

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(0, y_max; length = 5)
        y = scale_value(v, 0, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, v))</text>""")
    end

    for (idx, event_type) in enumerate(event_types)
        points = String[]
        for (time, value) in zip(times, series[event_type])
            x = scale_value(time, x_min, x_max, left, left + plot_w)
            y = scale_value(value, 0, y_max, top + plot_h, top)
            push!(points, @sprintf("%.2f,%.2f", x, y))
        end
        color = colors[mod1(idx, length(colors))]
        push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="$color" stroke-width="2"/>""")
        legend_x = left + 12 + (idx - 1) * 118
        push!(rows, """<rect x="$legend_x" y="$(height - 46)" width="10" height="10" fill="$color"/>""")
        push!(rows, """<text x="$(legend_x + 16)" y="$(height - 37)" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(svg_escape(labels[idx]))</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_bar_plot(labels::Vector{String}, values::Vector{Int}, title::String, output_path::String)
    width = 760
    height = 360
    left = 72
    right = 24
    top = 50
    bottom = 86
    plot_w = width - left - right
    plot_h = height - top - bottom
    max_value = max(maximum(values), 1)
    bar_gap = 18
    bar_w = (plot_w - bar_gap * (length(values) - 1)) / length(values)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">$(svg_escape(title))</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>"""
    ]

    for v in range(0, max_value; length = 5)
        y = scale_value(v, 0, max_value, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, v))</text>""")
    end

    for (idx, value) in enumerate(values)
        x = left + (idx - 1) * (bar_w + bar_gap)
        bar_h = scale_value(value, 0, max_value, 0, plot_h)
        y = top + plot_h - bar_h
        push!(rows, """<rect x="$x" y="$y" width="$bar_w" height="$bar_h" fill="#2563eb"/>""")
        push!(rows, """<text x="$(x + bar_w / 2)" y="$(y - 6)" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#111827">$value</text>""")
        push!(rows, """<text x="$(x + bar_w / 2)" y="$(top + plot_h + 24)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#374151">$(svg_escape(labels[idx]))</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_plot_index(output_dir::String)
    rows = [
        "<!doctype html>",
        "<html><head><meta charset=\"utf-8\"><title>BankSim demo plots</title>",
        "<style>body{font-family:Arial,sans-serif;margin:32px;color:#111827;background:#fff}main{max-width:980px;margin:auto}section{margin:0 0 28px}img{max-width:100%;border:1px solid #e5e7eb;background:white}h1{font-size:24px}h2{font-size:16px;margin-bottom:10px}</style>",
        "</head><body><main><h1>BankSim Demo Plots</h1>",
        "<section><h2>Bank reserves over time</h2><img src=\"bank_reserves.svg\" alt=\"Bank reserves over time\"></section>",
        "<section><h2>Client loan decisions over time</h2><img src=\"client_loan_decisions_over_time.svg\" alt=\"Client loan decisions over time\"></section>",
        "<section><h2>Default events over time</h2><img src=\"default_events_over_time.svg\" alt=\"Default events over time\"></section>",
        "<section><h2>Client loan decision totals</h2><img src=\"client_loan_decisions.svg\" alt=\"Client loan decision totals\"></section>",
        "</main></body></html>"
    ]
    write(joinpath(output_dir, "index.html"), join(rows, "\n"))
end

function event_count(events::DataFrame, event_type::String)
    return count(==(event_type), events.event_type)
end

function run_demo()
    if isdir(DEMO_RESULTS_DIR)
        rm(DEMO_RESULTS_DIR; recursive = true, force = true)
    end

    mkpath(DEMO_RESULTS_DIR)
    mkpath(DEMO_PLOTS_DIR)

    scenario = generate_demand_scenario(
        DEMO_SCENARIO_SEED,
        DEMO_DURATION_DAYS,
        CLIENT_LOAN_AMOUNT_RANGE,
        DEMO_CLIENT_LOAN_TERMS,
        CLIENT_LOAN_DEFAULT_PROB_RANGE,
        DEMO_CLIENT_LOAN_REQUESTS_PER_DAY,
        CLIENT_DEPOSIT_AMOUNT_RANGE,
        DEMO_CLIENT_DEPOSIT_TERMS,
        DEMO_CLIENT_DEPOSIT_REQUESTS_PER_DAY
    )

    sim = setup_simulation(
        DEMO_NUM_BANKS,
        TOTAL_INITIAL_RESERVES,
        DEMO_MIN_RESERVES_FACTOR,
        R_CLIENT_LOAN,
        R_BANK_LOAN,
        R_DEPOSIT,
        INTERBANK_LOAN_TERM,
        scenario,
        DEMO_RUN_SEED
    )

    println("Running single-scenario demo...")
    println("banks=$(DEMO_NUM_BANKS), min_reserve=$(DEMO_MIN_RESERVES_FACTOR), scenario_seed=$(DEMO_SCENARIO_SEED), run_seed=$(DEMO_RUN_SEED)")

    log_bank_states!(sim)
    run_simulation!(sim)

    events = events_dataframe(1, sim.event_log)
    metrics = DataFrame([compute_run_metrics(1, events)])
    bank_states = copy(sim.history_banks)
    bank_states.net_worth = [bank_net_worth(row) for row in eachrow(bank_states)]

    CSV.write(joinpath(DEMO_RESULTS_DIR, "events.csv"), events)
    CSV.write(joinpath(DEMO_RESULTS_DIR, "bank_states.csv"), bank_states)
    CSV.write(joinpath(DEMO_RESULTS_DIR, "metrics.csv"), metrics)

    save_bank_reserves_plot(bank_states, joinpath(DEMO_PLOTS_DIR, "bank_reserves.svg"))
    save_cumulative_event_plot(
        events,
        ["EventRequestClientLoan", "EventGrantClientLoan", "EventRejectClientLoan", "EventGrantBankLoan"],
        ["requested", "granted", "rejected", "interbank"],
        "Client loan decisions over time",
        joinpath(DEMO_PLOTS_DIR, "client_loan_decisions_over_time.svg")
    )
    save_cumulative_event_plot(
        events,
        ["EventClientLoanDefaulted", "EventDepositDefaulted", "EventBankLoanDefaulted"],
        ["client loans", "deposits", "interbank"],
        "Default events over time",
        joinpath(DEMO_PLOTS_DIR, "default_events_over_time.svg")
    )
    save_bar_plot(
        ["requested", "granted", "rejected", "interbank"],
        [
            event_count(events, "EventRequestClientLoan"),
            event_count(events, "EventGrantClientLoan"),
            event_count(events, "EventRejectClientLoan"),
            event_count(events, "EventGrantBankLoan")
        ],
        "Client loan decisions",
        joinpath(DEMO_PLOTS_DIR, "client_loan_decisions.svg")
    )
    save_plot_index(DEMO_PLOTS_DIR)

    println("Demo completed.")
    println("Events: $(joinpath(DEMO_RESULTS_DIR, "events.csv"))")
    println("Bank states: $(joinpath(DEMO_RESULTS_DIR, "bank_states.csv"))")
    println("Metrics: $(joinpath(DEMO_RESULTS_DIR, "metrics.csv"))")
    println("Plots: $(joinpath(DEMO_PLOTS_DIR, "index.html"))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    run_demo()
end
