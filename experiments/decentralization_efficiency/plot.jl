using CSV
using DataFrames
using Printf

include("config.jl")

const HEATMAP_METRICS = [
    (:liquidity_score, "Liquidity score", "heatmap_liquidity_score.svg"),
    (:loan_volume_acceptance_rate, "Loan volume acceptance rate", "heatmap_loan_volume_acceptance_rate.svg"),
    (:deposit_volume_repay_rate, "Deposit repayment rate", "heatmap_deposit_volume_repay_rate.svg"),
    (:bank_net_growth_ratio, "Bank net worth growth", "heatmap_bank_net_growth_ratio.svg"),
    (:interbank_dependency_rate, "Interbank dependency rate", "heatmap_interbank_dependency_rate.svg"),
    (:liquidity_stress_volume_rate, "Loan rejection rate", "heatmap_loan_rejection_rate.svg")
]

function svg_escape(value)
    text = string(value)
    text = replace(text, "&" => "&amp;")
    text = replace(text, "<" => "&lt;")
    text = replace(text, ">" => "&gt;")
    text = replace(text, "\"" => "&quot;")
    return text
end

function metric_value(row, metric::Symbol)
    value = row[metric]
    return ismissing(value) ? missing : Float64(value)
end

function metric_bounds(df::DataFrame, metric::Symbol)
    values = [metric_value(row, metric) for row in eachrow(df)]
    observed = collect(skipmissing(values))
    isempty(observed) && return 0.0, 1.0

    lo = minimum(observed)
    hi = maximum(observed)
    if lo == hi
        padding = max(abs(lo) * 0.05, 0.01)
        return lo - padding, hi + padding
    end
    return lo, hi
end

function hex_color(r::Int, g::Int, b::Int)
    return @sprintf("#%02x%02x%02x", clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
end

function interpolate_color(value::Float64, lo::Float64, hi::Float64)
    t = clamp((value - lo) / (hi - lo), 0.0, 1.0)

    anchors = [
        (68, 1, 84),
        (49, 104, 142),
        (53, 183, 121),
        (253, 231, 37)
    ]

    scaled = t * (length(anchors) - 1)
    idx = min(floor(Int, scaled) + 1, length(anchors) - 1)
    u = scaled - (idx - 1)

    a = anchors[idx]
    b0 = anchors[idx + 1]
    r = round(Int, (1 - u) * a[1] + u * b0[1])
    g = round(Int, (1 - u) * a[2] + u * b0[2])
    b = round(Int, (1 - u) * a[3] + u * b0[3])

    return hex_color(r, g, b)
end

function text_color(fill::String)
    r = parse(Int, fill[2:3], base = 16)
    g = parse(Int, fill[4:5], base = 16)
    b = parse(Int, fill[6:7], base = 16)
    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance > 145 ? "#1f2933" : "#f8fafc"
end

function format_value(value)
    if ismissing(value)
        return "NA"
    elseif abs(value) >= 10
        return @sprintf("%.1f", value)
    else
        return @sprintf("%.3f", value)
    end
end

function analysis_window_label(df::DataFrame)
    columns = Symbol.(names(df))
    if :analysis_start_day in columns && :analysis_end_day in columns && nrow(df) > 0
        start_day = first(skipmissing(df.analysis_start_day))
        end_day = first(skipmissing(df.analysis_end_day))
        return "Analysis window: days $(start_day)-$(end_day)"
    end
    return "Analysis window: days $(ANALYSIS_START_DAY)-$(ANALYSIS_END_DAY)"
end

function save_heatmap(df::DataFrame, metric::Symbol, title::String, output_path::String)
    banks = sort(unique(df.NUM_BANKS))
    reserves = sort(unique(df.MIN_RESERVES_FACTOR))

    left = 104
    top = 64
    cell_w = 66
    cell_h = 58
    right = 28
    bottom = 78
    width = left + length(banks) * cell_w + right
    height = top + length(reserves) * cell_h + bottom

    lo, hi = metric_bounds(df, metric)
    rows = String[]

    push!(rows, """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""")
    push!(rows, """<rect width="100%" height="100%" fill="#ffffff"/>""")
    push!(rows, """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="18" font-weight="700" fill="#111827">$(svg_escape(title))</text>""")
    push!(rows, """<text x="$(width / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Number of banks</text>""")
    push!(rows, """<text x="$(width / 2)" y="$(height - 42)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#6b7280">$(svg_escape(analysis_window_label(df)))</text>""")
    push!(rows, """<text x="18" y="$(top + length(reserves) * cell_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + length(reserves) * cell_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Minimum reserve factor</text>""")

    for (j, bank_count) in enumerate(banks)
        x = left + (j - 1) * cell_w + cell_w / 2
        push!(rows, """<text x="$x" y="$(top - 14)" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#374151">$bank_count</text>""")
    end

    for (i, reserve) in enumerate(reserves)
        y = top + (i - 1) * cell_h + cell_h / 2
        push!(rows, """<text x="$(left - 14)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(format_value(reserve))</text>""")

        for (j, bank_count) in enumerate(banks)
            selected = filter(row -> row.NUM_BANKS == bank_count && row.MIN_RESERVES_FACTOR == reserve, df)
            value = isempty(selected) ? missing : metric_value(first(eachrow(selected)), metric)
            fill = ismissing(value) ? "#e5e7eb" : interpolate_color(value, lo, hi)
            color = ismissing(value) ? "#6b7280" : text_color(fill)
            x = left + (j - 1) * cell_w
            y0 = top + (i - 1) * cell_h

            push!(rows, """<rect x="$x" y="$y0" width="$cell_w" height="$cell_h" fill="$fill" stroke="#ffffff" stroke-width="1"/>""")
            push!(rows, """<text x="$(x + cell_w / 2)" y="$(y0 + cell_h / 2 + 4)" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="$color">$(format_value(value))</text>""")
        end
    end

    push!(rows, "</svg>")

    write(output_path, join(rows, "\n"))
    println("Saved $(output_path)")
end

function save_metric_index(output_dir::String, metrics)
    rows = [
        "<!doctype html>",
        "<html><head><meta charset=\"utf-8\"><title>Decentralization efficiency plots</title>",
        "<style>body{font-family:Arial,sans-serif;margin:32px;color:#111827;background:#fff}main{max-width:960px;margin:auto}section{margin:0 0 28px}img{max-width:100%;background:white;border:1px solid #e5e7eb}h1{font-size:24px}h2{font-size:16px;margin-bottom:10px}</style>",
        "</head><body><main><h1>Decentralization Efficiency Plots</h1>"
    ]

    for (_, title, filename) in metrics
        push!(rows, "<section><h2>$(svg_escape(title))</h2><img src=\"$(svg_escape(filename))\" alt=\"$(svg_escape(title))\"></section>")
    end

    push!(rows, "</main></body></html>")
    write(joinpath(output_dir, "index.html"), join(rows, "\n"))
end

function build_plots(results_dir::String = length(ARGS) > 0 ? ARGS[1] : RESULTS_DIR)
    summary_path = joinpath(results_dir, "summary.csv")
    output_dir = joinpath(results_dir, "plots")
    mkpath(output_dir)

    df = CSV.read(summary_path, DataFrame)

    for (metric, title, filename) in HEATMAP_METRICS
        save_heatmap(df, metric, title, joinpath(output_dir, filename))
    end

    save_metric_index(output_dir, HEATMAP_METRICS)
    println("Plot index saved to $(joinpath(output_dir, "index.html"))")
end

if abspath(PROGRAM_FILE) == @__FILE__
    build_plots()
end
