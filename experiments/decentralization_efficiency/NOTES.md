# Decentralization Efficiency Notes

## What Has Been Done

The experiment has been refactored into a reproducible pipeline:

- demand scenarios are generated from explicit scenario seeds,
- the same aggregate demand stream can be reused across market configurations,
- request routing to banks is controlled by a separate run seed,
- simulation output is summarized into per-run metrics,
- aggregated summaries are written by parameter setting,
- plots are generated from saved summary files.

The model now has a clearer event-log structure. Simulation runs produce canonical event records for:

- client loan requests, grants, rejections, repayments, and defaults,
- client deposit requests, grants, repayments, and defaults,
- interbank loan requests, grants, repayments, and defaults,
- bank creation events.

The demo entrypoint was also simplified. It now runs one fixed scenario and writes:

- `events.csv`,
- `bank_states.csv`,
- `metrics.csv`,
- simple plots of reserves, loan decisions, and default events.

The full `decentralization_efficiency` experiment remains the main analysis. The demo is only meant to show how the simulation works.

## Current Interpretation

The experiment is best understood as a zero-intelligence liquidity model:

- client demand is exogenous,
- banks follow simple balance-sheet rules,
- interbank lending is used as a short-term liquidity mechanism,
- the main object of study is liquidity allocation under reserve constraints.

The model should not be presented as a realistic banking accounting model. Metrics such as bank net worth are useful as internal balance-sheet summaries, but the stronger demo plots are reserves, accepted/rejected credit, defaults, and interbank dependency.

## Analysis Window

The current analysis often uses the full settlement window. This may distort interpretation.

For the main decentralization analysis, metrics should probably be computed over:

```text
[warmup, active demand flow]
```

rather than over the entire period until the last loan or deposit matures.

Reason:

- demand is generated only during the active flow horizon,
- repayments and defaults continue after demand stops,
- including the full settlement tail can overemphasize end-of-run balance-sheet cleanup,
- cumulative decision plots become flat after demand stops, while repayment/default plots continue moving.

A better reporting setup would distinguish:

- active demand horizon,
- settlement horizon,
- analysis window.

## Observed Effects To Investigate

Some effects in the current runs look interesting but need careful interpretation:

- interbank default rates can be relatively high,
- client loan decision curves sometimes change slope around the middle of the active horizon,
- reserve dynamics appear to move toward a quasi-stationary region and then create secondary effects in lending and repayment behavior.

The change in client-loan slope may indicate that the system enters a different liquidity regime once reserves, liabilities, and outstanding loans reach a certain balance. This could be a real model effect rather than a bug, but it needs to be checked against event timing and balance-sheet state.

## Next Questions

1. Should experiment metrics be computed only on events inside `[warmup, active_flow_end]`?
2. Should repayment/default metrics be reported separately for active-flow and settlement windows?
3. What exactly drives high interbank default rates?
4. Does the client-loan slope change coincide with reserve stabilization, deposit maturity waves, or interbank loan defaults?
5. Should the demo expose the active demand horizon visually so the settlement tail is easier to interpret?

## Suggested Next Refactoring

Add explicit experiment window parameters:

```julia
warmup_days
active_flow_days
settlement_days
analysis_start_day
analysis_end_day
```

Then compute metrics with a clear rule:

- decision metrics on active-flow events,
- repayment/default metrics either on active-flow maturities or reported separately for settlement,
- final balance-sheet metrics at explicit snapshot days.

