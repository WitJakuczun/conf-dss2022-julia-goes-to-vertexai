struct Solution
    model::UCModel
    problem::Problem
    production_total::Dict{String, Float64}
    exchanges_total::Dict{String, Float64}
    total_units_in_use::Dict{String, Float64}
    unit_in_use::Dict{String, Dict{String, Float64}}
    unit_turn_on::Dict{String, Dict{String, Float64}}
end

function collect_production_total(model::UCModel)
    production_vars = [v for v in all_variables(model.model) if occursin("vProduction", name(v))]
    production_total = Dict{String, Float64}()

    for p in model.problem.periods
        prod_vars_period = [value(v) for v in production_vars if occursin(p, name(v))]
        production_total[p] = sum(prod_vars_period)
    end

    production_total
end

function collect_exchanges_total(model::UCModel)
    exchanges_vars = [v for v in all_variables(model.model) if occursin("vExchange", name(v))]
    exchanges_total = Dict{String, Float64}()

    for p in model.problem.periods
        exch_vars_period = [value(v) for v in exchanges_vars if occursin(p, name(v))]
        exchanges_total[p] = sum(exch_vars_period)
    end

    exchanges_total
end

function collect_total_units_in_use(model::UCModel)
    in_use_vars = [v for v in all_variables(model.model) if occursin("vUnitInUse", name(v))]
    total_in_use = Dict{String, Float64}()

    for p in model.problem.periods
        in_use_vars_period = [value(v) for v in in_use_vars if occursin(p, name(v))]
        total_in_use[p] = sum(in_use_vars_period)
    end

    total_in_use
end

function collect_unit_in_use(model::UCModel)
    in_use_vars = [v for v in all_variables(model.model) if occursin("vUnitInUse", name(v))]
    in_use = Dict{String, Dict{String, Float64}}()

    for u in model.problem.units
        u_in_use = Dict{String, Float64}(
            [
                (p, value(v)) for p in model.problem.periods for v in in_use_vars if occursin(p, name(v)) && occursin(u, name(v))
            ])
        in_use[u] = u_in_use
    end

    in_use
end

function collect_unit_turn_on(model::UCModel)
    turn_on_vars = [v for v in all_variables(model.model) if occursin("vTurnUnitOn", name(v))]
    turn_on = Dict{String, Dict{String, Float64}}()

    for u in model.problem.units
        u_turn_on = Dict{String, Float64}(
            [
                (p, value(v)) for p in model.problem.periods for v in turn_on_vars if occursin(p, name(v)) && occursin(u, name(v))
            ])
        turn_on[u] = u_turn_on
    end

    turn_on
end

function solve(model::UCModel)
    optimize!(model.model)

    vars = all_variables(model.model)
    @info "Model has $(length(vars)) variables"

    objective_vars = ["$(name(v)) -> $(value(v))" for v in vars if occursin("vObjective", name(v))]

    foreach(println, objective_vars)

    @info "Total objective -> $(objective_value(model.model))"

    Solution(
        model,
        model.problem,
        collect_production_total(model),
        collect_exchanges_total(model),
        collect_total_units_in_use(model),
        collect_unit_in_use(model),
        collect_unit_turn_on(model))
end
