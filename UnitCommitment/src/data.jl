struct Exchange
    max::Float64
    price::Float64
end

struct Problem
    periods::Vector{String}
    demand::Dict{String, Float64}
    units::Vector{String}
    units_properties::Dict{String, Dict{String, Union{Float64, Missing}}}
    units_maintenance::Dict{String, Dict{String, Union{Float64, Missing}}}
    exchanges::Dict{String, Exchange}
    weights::Dict{String, Float64}

    next_period::Dict{String, String}

    function Problem(periods, demand, units, units_properties, units_maintenance, exchanges, weights)
        next_period=Dict{String, String}()
        for pi in 1:(length(periods)-1)
            next_period[periods[pi]] = periods[pi+1]
        end

        new(
            periods,
            demand,
            units,
            units_properties,
            units_maintenance,
            exchanges,
            weights,
            next_period
        )
    end
end

function load_periods(data_path::String)
    periods_df = CSV.read(data_path, DataFrame)

    unique(periods_df[!, :Periods])
end

function load_demand(data_path::String)
    periods_df = CSV.read(data_path, DataFrame)
    demand = Dict{String, Float64}()
    for pd in eachrow(periods_df)
        demand[pd.Periods] = pd.Baseline
    end

    demand
end

function load_units(data_path::String)
    units_df = CSV.read(data_path, DataFrame)

    unique(units_df[!, :Units])
end

function load_units_properties(data_path::String)
    units_df = CSV.read(data_path, DataFrame)

    units_props = Dict{String, Dict{String, Union{Float64, Missing}}}()
    for up in eachrow(units_df)
        up_v = get!(units_props, up.Units, Dict{String, Union{Float64, Missing}}())
        up_v[up.UnitProperties] = up.Baseline
    end

    units_props
end

function load_exchanges(data_path::String)
    exchanges_df = CSV.read(data_path, DataFrame)

    exchanges = Dict{String, Exchange}()
    for ex in eachrow(exchanges_df)
        exchanges[ex.Periods] = Exchange(ex.Max, ex.Price)
    end

    exchanges
end

function load_units_maintenance(data_path::String)
    units_df = CSV.read(data_path, DataFrame)

    units_maintenance = Dict{String, Dict{String, Union{Float64, Missing}}}()
    for up in eachrow(units_df)
        up_v = get!(units_maintenance, up.Periods, Dict{String, Union{Float64, Missing}}())
        up_v[up.Units] = up.Baseline
    end

    units_maintenance
end

function load_weights(data_path::String)
    weights_df = CSV.read(data_path, DataFrame)
    weights = Dict{String, Float64}()

    for w in eachrow(weights_df)
        weights[w.Weights] = w.Baseline
    end

    weights
end

function load_data(path_loads::String, path_units::String, path_maintenance::String, path_exchanges::String, path_weights::String)
    periods = load_periods(path_loads)
    demand = load_demand(path_loads)
    units = load_units(path_units)
    units_properties = load_units_properties(path_units)
    units_maintenance = load_units_maintenance(path_maintenance)
    exchanges = load_exchanges(path_exchanges)
    weights = load_weights(path_weights)
    problem = Problem(
        periods,
        demand,
        units,
        units_properties,
        units_maintenance,
        exchanges,
        weights
    )

    problem
end
