using DataFrames
using Printf

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

function hex_color(r::Int, g::Int, b::Int)
    return @sprintf("#%02x%02x%02x", clamp(r, 0, 255), clamp(g, 0, 255), clamp(b, 0, 255))
end

function push_settlement_band!(
    rows::Vector{String},
    x_min::Real,
    x_max::Real,
    left::Real,
    top::Real,
    plot_w::Real,
    plot_h::Real
)
    if DEMO_DURATION_DAYS < x_max
        x = scale_value(DEMO_DURATION_DAYS, x_min, x_max, left, left + plot_w)
        band_w = left + plot_w - x
        push!(rows, """<rect x="$x" y="$top" width="$band_w" height="$plot_h" fill="#f3f4f6" opacity="0.75"/>""")
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#9ca3af" stroke-width="1" stroke-dasharray="4 4"/>""")
        push!(rows, """<text x="$(x + 8)" y="$(top + 16)" font-family="Arial, sans-serif" font-size="10" fill="#6b7280">settlement</text>""")
    end
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

    push_settlement_band!(rows, x_min, x_max, left, top, plot_w, plot_h)

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(y_min, y_max; length = 5)
        y = scale_value(v, y_min, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, :money))</text>""")
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

function save_system_reserves_plot(bank_states::DataFrame, output_path::String)
    bank_states.required_reserves = bank_states.total_liabilities .* bank_states.min_reserves
    grouped = combine(
        groupby(bank_states, :time),
        :reserves => sum => :system_reserves,
        :required_reserves => sum => :required_reserves
    )
    sort!(grouped, :time)

    width = 920
    height = 360
    left = 78
    right = 26
    top = 48
    bottom = 64
    plot_w = width - left - right
    plot_h = height - top - bottom

    x_min, x_max = minimum(grouped.time), maximum(grouped.time)
    y_min = 0.0
    y_max = max(maximum(grouped.system_reserves), maximum(grouped.required_reserves))
    y_pad = max((y_max - y_min) * 0.08, 1.0)
    y_min -= y_pad
    y_max += y_pad

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">System reserves over time</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Total reserves</text>"""
    ]

    push_settlement_band!(rows, x_min, x_max, left, top, plot_w, plot_h)

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(y_min, y_max; length = 5)
        y = scale_value(v, y_min, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, :money))</text>""")
    end

    reserve_points = String[]
    required_points = String[]
    for row in eachrow(grouped)
        x = scale_value(row.time, x_min, x_max, left, left + plot_w)
        reserve_y = scale_value(row.system_reserves, y_min, y_max, top + plot_h, top)
        required_y = scale_value(row.required_reserves, y_min, y_max, top + plot_h, top)
        push!(reserve_points, @sprintf("%.2f,%.2f", x, reserve_y))
        push!(required_points, @sprintf("%.2f,%.2f", x, required_y))
    end

    push!(rows, """<polyline points="$(join(reserve_points, " "))" fill="none" stroke="#2563eb" stroke-width="2.5"/>""")
    push!(rows, """<polyline points="$(join(required_points, " "))" fill="none" stroke="#dc2626" stroke-width="2" stroke-dasharray="5 4"/>""")
    push!(rows, """<rect x="$(left + 12)" y="$(height - 44)" width="10" height="10" fill="#2563eb"/>""")
    push!(rows, """<text x="$(left + 28)" y="$(height - 35)" font-family="Arial, sans-serif" font-size="11" fill="#374151">actual reserves</text>""")
    push!(rows, """<line x1="$(left + 146)" y1="$(height - 39)" x2="$(left + 166)" y2="$(height - 39)" stroke="#dc2626" stroke-width="2" stroke-dasharray="5 4"/>""")
    push!(rows, """<text x="$(left + 174)" y="$(height - 35)" font-family="Arial, sans-serif" font-size="11" fill="#374151">required reserves</text>""")
    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_balance_sheet_plot(events::DataFrame, bank_states::DataFrame, output_path::String; snapshot_day::Int = DEMO_DURATION_DAYS)
    bs = system_balance_sheet(events, bank_states, snapshot_day)
    width = 920
    height = 420
    left = 72
    top = 62
    panel_gap = 60
    panel_w = 360
    bar_h = 28
    bar_gap = 18
    max_value = max(maximum(bs.asset_values), maximum(bs.liability_values), 1.0)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">System balance sheet at day $snapshot_day</text>""",
        """<text x="$left" y="$top" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#111827">Assets</text>""",
        """<text x="$(left + panel_w + panel_gap)" y="$top" font-family="Arial, sans-serif" font-size="14" font-weight="700" fill="#111827">Liabilities and equity</text>"""
    ]

    for (idx, (label, value)) in enumerate(zip(bs.assets, bs.asset_values))
        y = top + 34 + (idx - 1) * (bar_h + bar_gap)
        w = scale_value(value, 0, max_value, 0, panel_w)
        push!(rows, """<text x="$left" y="$(y - 6)" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(svg_escape(label))</text>""")
        push!(rows, """<rect x="$left" y="$y" width="$w" height="$bar_h" fill="#2563eb"/>""")
        push!(rows, """<text x="$(left + w + 8)" y="$(y + 19)" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#111827">$(format_bar_value(value, :money))</text>""")
    end

    right_left = left + panel_w + panel_gap
    for (idx, (label, value)) in enumerate(zip(bs.liabilities, bs.liability_values))
        y = top + 34 + (idx - 1) * (bar_h + bar_gap)
        w = scale_value(value, 0, max_value, 0, panel_w)
        fill = label == "equity / net worth" ? "#16a34a" : "#dc2626"
        push!(rows, """<text x="$right_left" y="$(y - 6)" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(svg_escape(label))</text>""")
        push!(rows, """<rect x="$right_left" y="$y" width="$w" height="$bar_h" fill="$fill"/>""")
        push!(rows, """<text x="$(right_left + w + 8)" y="$(y + 19)" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#111827">$(format_bar_value(value, :money))</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_system_liquidity_buffer_plot(bank_states::DataFrame, output_path::String)
    bank_states.required_reserves = bank_states.total_liabilities .* bank_states.min_reserves
    grouped = combine(
        groupby(bank_states, :time),
        :reserves => sum => :system_reserves,
        :required_reserves => sum => :required_reserves
    )
    sort!(grouped, :time)
    grouped.liquidity_buffer = grouped.system_reserves .- grouped.required_reserves

    width = 920
    height = 360
    left = 82
    right = 26
    top = 48
    bottom = 64
    plot_w = width - left - right
    plot_h = height - top - bottom

    x_min, x_max = minimum(grouped.time), maximum(grouped.time)
    y_min, y_max = minimum(grouped.liquidity_buffer), maximum(grouped.liquidity_buffer)
    y_pad = max((y_max - y_min) * 0.08, 1.0)
    y_min -= y_pad
    y_max += y_pad

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">System liquidity buffer over time</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Reserves above requirement</text>"""
    ]

    push_settlement_band!(rows, x_min, x_max, left, top, plot_w, plot_h)

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(y_min, y_max; length = 5)
        y = scale_value(v, y_min, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, :money))</text>""")
    end

    if y_min < 0 < y_max
        zero_y = scale_value(0, y_min, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$zero_y" x2="$(left + plot_w)" y2="$zero_y" stroke="#dc2626" stroke-width="1" stroke-dasharray="4 4"/>""")
    end

    points = String[]
    for row in eachrow(grouped)
        x = scale_value(row.time, x_min, x_max, left, left + plot_w)
        y = scale_value(row.liquidity_buffer, y_min, y_max, top + plot_h, top)
        push!(points, @sprintf("%.2f,%.2f", x, y))
    end

    push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="#2563eb" stroke-width="2.5"/>""")
    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_rolling_loan_volume_plot(events::DataFrame, output_path::String; window_days::Int = 30)
    event_types = ["EventRequestClientLoan", "EventGrantClientLoan"]
    labels = ["requested", "granted"]
    colors = ["#2563eb", "#16a34a"]
    daily = Dict(event_type => daily_principal_by_type(events, event_type, DEMO_DURATION_DAYS) for event_type in event_types)
    times = collect(1:DEMO_DURATION_DAYS)
    series = Dict(event_type => [rolling_sum(daily[event_type], day, window_days) for day in times] for event_type in event_types)

    width = 920
    height = 380
    left = 82
    right = 28
    top = 48
    bottom = 70
    plot_w = width - left - right
    plot_h = height - top - bottom
    y_max = max(maximum(vcat(values(series)...)), 1.0)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">Rolling client loan volume</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">$(window_days)-day principal</text>"""
    ]

    for t in range(1, DEMO_DURATION_DAYS; length = 5)
        x = scale_value(t, 1, DEMO_DURATION_DAYS, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(0, y_max; length = 5)
        y = scale_value(v, 0, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, :money))</text>""")
    end

    for (idx, event_type) in enumerate(event_types)
        points = String[]
        for (time, value) in zip(times, series[event_type])
            x = scale_value(time, 1, DEMO_DURATION_DAYS, left, left + plot_w)
            y = scale_value(value, 0, y_max, top + plot_h, top)
            push!(points, @sprintf("%.2f,%.2f", x, y))
        end
        push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="$(colors[idx])" stroke-width="2.5"/>""")
        legend_x = left + 12 + (idx - 1) * 118
        push!(rows, """<rect x="$legend_x" y="$(height - 46)" width="10" height="10" fill="$(colors[idx])"/>""")
        push!(rows, """<text x="$(legend_x + 16)" y="$(height - 37)" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(labels[idx])</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_cumulative_principal_plot(events::DataFrame, event_types::Vector{String}, labels::Vector{String}, title::String, output_path::String)
    colors = ["#2563eb", "#16a34a", "#dc2626", "#9333ea", "#ea580c", "#0891b2"]
    width = 920
    height = 420
    left = 82
    right = 28
    top = 48
    bottom = 70
    plot_w = width - left - right
    plot_h = height - top - bottom

    times, series = cumulative_principal_series(events, event_types)
    x_min, x_max = minimum(times), maximum(times)
    y_max = max(maximum(vcat(values(series)...)), 1.0)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">$(svg_escape(title))</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Cumulative principal</text>"""
    ]

    push_settlement_band!(rows, x_min, x_max, left, top, plot_w, plot_h)

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(0, y_max; length = 5)
        y = scale_value(v, 0, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, :money))</text>""")
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

function save_rolling_acceptance_plot(events::DataFrame, output_path::String; window_days::Int = 30)
    loan_events = filter(row -> row.time <= DEMO_DURATION_DAYS, events)
    request_counts = Dict(day => 0 for day in 1:DEMO_DURATION_DAYS)
    grant_counts = Dict(day => 0 for day in 1:DEMO_DURATION_DAYS)

    for row in eachrow(loan_events)
        if row.event_type == "EventRequestClientLoan"
            request_counts[row.time] += 1
        elseif row.event_type == "EventGrantClientLoan"
            grant_counts[row.time] += 1
        end
    end

    times = collect(1:DEMO_DURATION_DAYS)
    rates = Float64[]
    for day in times
        start_day = max(1, day - window_days + 1)
        requests = sum(request_counts[d] for d in start_day:day)
        grants = sum(grant_counts[d] for d in start_day:day)
        push!(rates, requests == 0 ? 0.0 : grants / requests)
    end

    width = 920
    height = 360
    left = 72
    right = 28
    top = 48
    bottom = 64
    plot_w = width - left - right
    plot_h = height - top - bottom
    x_min, x_max = minimum(times), maximum(times)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">Rolling loan acceptance rate</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Acceptance rate</text>"""
    ]

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in 0.0:0.25:1.0
        y = scale_value(v, 0, 1, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(@sprintf("%.0f%%", 100 * v))</text>""")
    end

    points = String[]
    for (time, rate) in zip(times, rates)
        x = scale_value(time, x_min, x_max, left, left + plot_w)
        y = scale_value(rate, 0, 1, top + plot_h, top)
        push!(points, @sprintf("%.2f,%.2f", x, y))
    end

    push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="#2563eb" stroke-width="2.5"/>""")
    push!(rows, """<text x="$(left + 12)" y="$(height - 40)" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(window_days)-day window</text>""")
    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_acceptance_vs_buffer_plot(events::DataFrame, bank_states::DataFrame, output_path::String; window_days::Int = 30)
    loan_events = filter(row -> row.time <= DEMO_DURATION_DAYS, events)
    request_counts = Dict(day => 0 for day in 1:DEMO_DURATION_DAYS)
    grant_counts = Dict(day => 0 for day in 1:DEMO_DURATION_DAYS)
    for row in eachrow(loan_events)
        if row.event_type == "EventRequestClientLoan"
            request_counts[row.time] += 1
        elseif row.event_type == "EventGrantClientLoan"
            grant_counts[row.time] += 1
        end
    end

    times = collect(1:DEMO_DURATION_DAYS)
    rates = Float64[]
    for day in times
        start_day = max(1, day - window_days + 1)
        requests = sum(request_counts[d] for d in start_day:day)
        grants = sum(grant_counts[d] for d in start_day:day)
        push!(rates, requests == 0 ? 0.0 : grants / requests)
    end

    buffer_by_time = Dict(row.time => row.liquidity_buffer for row in eachrow(liquidity_buffer_series(bank_states)))
    buffers = [buffer_by_time[day] for day in times]
    min_buffer, max_buffer = minimum(buffers), maximum(buffers)
    normalized_buffers = max_buffer == min_buffer ? fill(0.5, length(buffers)) : [(b - min_buffer) / (max_buffer - min_buffer) for b in buffers]

    width = 920
    height = 380
    left = 72
    right = 28
    top = 48
    bottom = 70
    plot_w = width - left - right
    plot_h = height - top - bottom

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">Rolling acceptance rate vs liquidity buffer</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>"""
    ]

    for t in range(1, DEMO_DURATION_DAYS; length = 5)
        x = scale_value(t, 1, DEMO_DURATION_DAYS, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in 0.0:0.25:1.0
        y = scale_value(v, 0, 1, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(@sprintf("%.0f%%", 100 * v))</text>""")
    end

    for (values, color, label, dash) in [
        (rates, "#2563eb", "acceptance rate", ""),
        (normalized_buffers, "#16a34a", "liquidity buffer normalized", " stroke-dasharray=\"5 4\"")
    ]
        points = String[]
        for (time, value) in zip(times, values)
            x = scale_value(time, 1, DEMO_DURATION_DAYS, left, left + plot_w)
            y = scale_value(value, 0, 1, top + plot_h, top)
            push!(points, @sprintf("%.2f,%.2f", x, y))
        end
        push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="$color" stroke-width="2.5"$dash/>""")
    end

    push!(rows, """<rect x="$(left + 12)" y="$(height - 46)" width="10" height="10" fill="#2563eb"/>""")
    push!(rows, """<text x="$(left + 28)" y="$(height - 37)" font-family="Arial, sans-serif" font-size="11" fill="#374151">acceptance rate</text>""")
    push!(rows, """<line x1="$(left + 156)" y1="$(height - 41)" x2="$(left + 176)" y2="$(height - 41)" stroke="#16a34a" stroke-width="2.5" stroke-dasharray="5 4"/>""")
    push!(rows, """<text x="$(left + 184)" y="$(height - 37)" font-family="Arial, sans-serif" font-size="11" fill="#374151">liquidity buffer normalized</text>""")
    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_client_loan_defaults_plot(events::DataFrame, output_path::String)
    save_cumulative_event_plot(
        events,
        ["EventClientLoanDefaulted"],
        ["client loan defaults"],
        "Client loan defaults over time",
        output_path
    )
end

function save_client_loan_repayment_value_plot(events::DataFrame, output_path::String)
    value_events = ["EventClientLoanRepaid", "EventClientLoanDefaulted"]
    labels = ["repaid value", "defaulted value"]
    colors = ["#16a34a", "#dc2626"]
    times = sort(unique(events.time))
    series = Dict(event_type => Float64[] for event_type in value_events)
    totals = Dict(event_type => 0.0 for event_type in value_events)

    for time in times
        today = filter(row -> row.time == time, events)
        for event_type in value_events
            selected = filter(row -> row.event_type == event_type && !ismissing(row.repayment), today)
            if !isempty(selected)
                totals[event_type] += sum(Float64.(selected.repayment))
            end
            push!(series[event_type], totals[event_type])
        end
    end

    width = 920
    height = 380
    left = 82
    right = 28
    top = 48
    bottom = 70
    plot_w = width - left - right
    plot_h = height - top - bottom
    x_min, x_max = minimum(times), maximum(times)
    y_max = max(maximum(vcat(values(series)...)), 1.0)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="28" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">Client loan repayment outcomes by value</text>""",
        """<line x1="$left" y1="$(top + plot_h)" x2="$(left + plot_w)" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<line x1="$left" y1="$top" x2="$left" y2="$(top + plot_h)" stroke="#374151" stroke-width="1"/>""",
        """<text x="$(left + plot_w / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Simulation day</text>""",
        """<text x="18" y="$(top + plot_h / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + plot_h / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Cumulative value</text>"""
    ]
    push_settlement_band!(rows, x_min, x_max, left, top, plot_w, plot_h)

    for t in range(x_min, x_max; length = 5)
        x = scale_value(t, x_min, x_max, left, left + plot_w)
        push!(rows, """<line x1="$x" y1="$top" x2="$x" y2="$(top + plot_h)" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$x" y="$(top + plot_h + 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(round(Int, t))</text>""")
    end

    for v in range(0, y_max; length = 5)
        y = scale_value(v, 0, y_max, top + plot_h, top)
        push!(rows, """<line x1="$left" y1="$y" x2="$(left + plot_w)" y2="$y" stroke="#e5e7eb" stroke-width="1"/>""")
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, :money))</text>""")
    end

    for (idx, event_type) in enumerate(value_events)
        points = String[]
        for (time, value) in zip(times, series[event_type])
            x = scale_value(time, x_min, x_max, left, left + plot_w)
            y = scale_value(value, 0, y_max, top + plot_h, top)
            push!(points, @sprintf("%.2f,%.2f", x, y))
        end
        push!(rows, """<polyline points="$(join(points, " "))" fill="none" stroke="$(colors[idx])" stroke-width="2.5"/>""")
        legend_x = left + 12 + (idx - 1) * 130
        push!(rows, """<rect x="$legend_x" y="$(height - 46)" width="10" height="10" fill="$(colors[idx])"/>""")
        push!(rows, """<text x="$(legend_x + 16)" y="$(height - 37)" font-family="Arial, sans-serif" font-size="11" fill="#374151">$(labels[idx])</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
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

    push_settlement_band!(rows, x_min, x_max, left, top, plot_w, plot_h)

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

function format_bar_value(value::Real, value_format::Symbol)
    if value_format == :money
        if abs(value) >= 1_000_000_000
            return @sprintf("%.2fB", value / 1_000_000_000)
        elseif abs(value) >= 1_000_000
            return @sprintf("%.1fM", value / 1_000_000)
        elseif abs(value) >= 1_000
            return @sprintf("%.1fK", value / 1_000)
        else
            return @sprintf("%.0f", value)
        end
    elseif value == round(value)
        return string(round(Int, value))
    elseif abs(value) >= 10
        return @sprintf("%.1f", value)
    else
        return @sprintf("%.3f", value)
    end
end

function save_bar_plot(labels::Vector{String}, values::Vector{<:Real}, title::String, output_path::String; value_format::Symbol = :count)
    width = 760
    height = 360
    left = 72
    right = 24
    top = 50
    bottom = 86
    plot_w = width - left - right
    plot_h = height - top - bottom
    max_value = max(maximum(Float64.(values)), 1.0)
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
        push!(rows, """<text x="$(left - 8)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="10" fill="#4b5563">$(format_bar_value(v, value_format))</text>""")
    end

    for (idx, value) in enumerate(values)
        x = left + (idx - 1) * (bar_w + bar_gap)
        bar_h = scale_value(value, 0, max_value, 0, plot_h)
        y = top + plot_h - bar_h
        push!(rows, """<rect x="$x" y="$y" width="$bar_w" height="$bar_h" fill="#2563eb"/>""")
        push!(rows, """<text x="$(x + bar_w / 2)" y="$(y - 6)" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" font-weight="700" fill="#111827">$(format_bar_value(value, value_format))</text>""")
        push!(rows, """<text x="$(x + bar_w / 2)" y="$(top + plot_h + 24)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#374151">$(svg_escape(labels[idx]))</text>""")
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end

function save_rejection_reasons_plot(events::DataFrame, output_path::String)
    reasons = [
        "negative_expected_value_credit_risk",
        "insufficient_liquidity_after_own_reserves",
        "insufficient_liquidity_even_after_interbank_funding",
        "reserve_constraint_violation"
    ]
    values = [count(row -> row.event_type == "EventRejectClientLoan" && !ismissing(row.reason) && row.reason == reason, eachrow(events)) for reason in reasons]
    save_bar_plot(reason_label.(reasons), values, "Rejected client loans by reason", output_path)
end

function save_interbank_matrix_plot(events::DataFrame, output_path::String)
    banks, matrix = interbank_lending_matrix(events)
    width = 520
    height = 500
    left = 92
    top = 72
    cell = 58
    max_value = max(maximum(collect(values(matrix))), 1.0)

    rows = String[
        """<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">""",
        """<rect width="100%" height="100%" fill="#ffffff"/>""",
        """<text x="$(width / 2)" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="20" font-weight="700" fill="#111827">Interbank lending matrix</text>""",
        """<text x="$(left + length(banks) * cell / 2)" y="$(height - 18)" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#374151">Borrower bank</text>""",
        """<text x="18" y="$(top + length(banks) * cell / 2)" text-anchor="middle" transform="rotate(-90 18 $(top + length(banks) * cell / 2))" font-family="Arial, sans-serif" font-size="12" fill="#374151">Lender bank</text>"""
    ]

    for (j, borrower) in enumerate(banks)
        x = left + (j - 1) * cell + cell / 2
        push!(rows, """<text x="$x" y="$(top - 14)" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#374151">$borrower</text>""")
    end
    for (i, lender) in enumerate(banks)
        y = top + (i - 1) * cell + cell / 2
        push!(rows, """<text x="$(left - 14)" y="$(y + 4)" text-anchor="end" font-family="Arial, sans-serif" font-size="11" fill="#374151">$lender</text>""")
        for (j, borrower) in enumerate(banks)
            value = matrix[(lender, borrower)]
            intensity = value / max_value
            fill = value == 0 ? "#f3f4f6" : hex_color(round(Int, 230 - 190 * intensity), round(Int, 245 - 105 * intensity), round(Int, 255 - 55 * intensity))
            x = left + (j - 1) * cell
            y0 = top + (i - 1) * cell
            push!(rows, """<rect x="$x" y="$y0" width="$cell" height="$cell" fill="$fill" stroke="#ffffff" stroke-width="1"/>""")
            label = value == 0 ? "0" : format_bar_value(value, :money)
            push!(rows, """<text x="$(x + cell / 2)" y="$(y0 + cell / 2 + 4)" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" font-weight="700" fill="#111827">$label</text>""")
        end
    end

    push!(rows, "</svg>")
    write(output_path, join(rows, "\n"))
end
