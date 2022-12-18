using JSON

struct Metrics
    objective_cost::Float64
    fixed_cost::Float64
    variable_cost::Float64
    startup_cost::Float64
    co2_cost::Float64
end

function to_dict(metrics::Metrics)
    Dict(String(key) => getfield(metrics, key) for key in propertynames(metrics))
end

function to_json(metrics::Metrics, jp::String)
    open(jp, "w") do f
        write(f, JSON.json(metrics))
    end
end

function evaluate(solution::Solution)
    model = solution.model.model
    Metrics(
        objective_value(model),
        value(variable_by_name(model, "vObjective[fixed_cost]")),
        value(variable_by_name(model, "vObjective[variable_cost]")),
        value(variable_by_name(model, "vObjective[startup_cost]")),
        value(variable_by_name(model, "vObjective[co2_cost]"))
    )
end
