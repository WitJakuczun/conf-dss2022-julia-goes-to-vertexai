function missing_to_zero(x::Union{Float64, Missing})
    ismissing(x) ? 0.0 : x
end

function cstrRampUpDown(model::JuMP.Model, vars::UCVars, problem::Problem)
    vProduction = vars.vProduction

    @constraint(model,
        cRampUpFirstPeriod[u=problem.units],
        vProduction[u, problem.periods[begin]] - missing_to_zero(problem.units_properties[u]["init_prod_level"])
            <= problem.units_properties[u]["ramp_up"]
    )
    @constraint(model,
        cRampDownFirstPeriod[u=problem.units],
        missing_to_zero(problem.units_properties[u]["init_prod_level"]) - vProduction[u, problem.periods[begin]]
            <= problem.units_properties[u]["ramp_down"]
    )

    @constraint(model,
        cRampUp[u=problem.units, p=problem.periods[begin:(end-1)]],
        vProduction[u, problem.next_period[p]]- vProduction[u, p] <= problem.units_properties[u]["ramp_up"]
    )

    @constraint(model,
        cRampDown[u=problem.units, p=problem.periods[begin:(end-1)]],
        vProduction[u, p] - vProduction[u, problem.next_period[p]] <= problem.units_properties[u]["ramp_down"]
    )
end

function cstrInitialState(model, vars, problem)
    vTurnUnitOn = vars.vTurnUnitOn
    vTurnUnitOff = vars.vTurnUnitOff
    vUnitInUse = vars.vUnitInUse

    for u in problem.units
        if !ismissing(problem.units_properties[u]["init_prod_level"])
            @constraint(model, [[u]],
                vTurnUnitOn[u, problem.periods[begin]] == 0,
                base_name = "cInitialState_1")
            @constraint(model, [[u]],
                vTurnUnitOff[u, problem.periods[begin]] + vUnitInUse[u, problem.periods[begin]] == 1,
                base_name = "cInitialState_2")
        else
            @constraint(model, [[u]],
                vTurnUnitOff[u, problem.periods[begin]] == 0,
                base_name="cInitialState_1")
            @constraint(model, [[u]],
                vTurnUnitOff[u, problem.periods[begin]] == vUnitInUse[u, problem.periods[begin]],
                base_name="cInitialState_2")
        end
    end
end

function cstrMinMaxGeneration(model, vars, problem)
    vProduction = vars.vProduction
    vUnitInUse = vars.vUnitInUse
    @constraint(model,
        cMaxGeneration[u=problem.units, p=problem.periods],
        vProduction[u,p] <= problem.units_properties[u]["max_generation"] * vUnitInUse[u, p]
    )

    @constraint(model,
        cMinGeneration[u=problem.units, p=problem.periods],
        vProduction[u,p] >= problem.units_properties[u]["min_generation"] * vUnitInUse[u, p]
    )
end

function cstrTurnUnitOnOff(model, vars, problem)
    vUnitInUse = vars.vUnitInUse
    vTurnUnitOff = vars.vTurnUnitOff
    vTurnUnitOn = vars.vTurnUnitOn

    # # Turn on/off
    @constraint(model,
        cTurnOnOff_1[u=problem.units, p=problem.periods[begin:(end-1)]],
        vUnitInUse[u, problem.next_period[p]] - vUnitInUse[u, p] <= vTurnUnitOn[u, problem.next_period[p]]
    )

    @constraint(model,
        cTurnOnOff_2[u=problem.units, p=problem.periods[begin:(end-1)]],
        vUnitInUse[u, problem.next_period[p]] + vUnitInUse[u, p] + vTurnUnitOn[u, problem.next_period[p]] <= 2
    )

    @constraint(model,
        cTurnOnOff_3[u=problem.units, p=problem.periods[begin:(end-1)]],
        vUnitInUse[u, p] - vUnitInUse[u, problem.next_period[p]] + vTurnUnitOn[u, problem.next_period[p]] == vTurnUnitOff[u, problem.next_period[p]]
    )
end

function cstrMinUpDownTime(model, vars, problem)
    vUnitInUse = vars.vUnitInUse
    vTurnUnitOff = vars.vTurnUnitOff
    vTurnUnitOn = vars.vTurnUnitOn

    # # Minimum uptime, downtime
    @constraint(model,
        cMinUp[u=problem.units, p=Int(problem.units_properties[u]["min_up"]):length(problem.periods)],

        sum(vTurnUnitOn[u, problem.periods[p2]] for p2 in (p - Int(problem.units_properties[u]["min_up"]) + 1):(p)) <= vUnitInUse[u, problem.periods[p]]
    )

    @constraint(model,
        cMinDown[u=problem.units, p=Int(problem.units_properties[u]["min_down"]):length(problem.periods)],
        sum(vTurnUnitOff[u, problem.periods[p2]] for p2 in (p - Int(problem.units_properties[u]["min_down"]) + 1):p) <= 1 - vUnitInUse[u, problem.periods[p]]
    )
end

function cstrDemandEnforce(model, vars, problem)
    vProduction = vars.vProduction
    vExchange = vars.vExchange
    # Enforcing demand
    # we use a >= here to be more robust,
    # objective will ensure  we produce efficiently
    @constraint(model,
        cMeetDemand[p=problem.periods],
        sum(vProduction[u, p] for u in problem.units)  + vExchange[p] >= problem.demand[p]
    )
end

function cstrMaxEchange(model, vars, problem)
    vExchange = vars.vExchange
    # # Maximum exchange
    @constraint(model,
        cMaxExchange[p=problem.periods],
        vExchange[p] <= (haskey(problem.exchanges, p) ? problem.exchanges[p].max : 0)
    )
end

function cstrUnitMaintenance(model, vars, problem)
    vUnitInUse = vars.vUnitInUse
    # Unit Maintenance
    @constraint(model,
        cUnitMaintenance[p=problem.periods, u=problem.units],
        vUnitInUse[u, p] <= (ismissing(problem.units_maintenance[p][u]) ? 1.0 : 0.0)
    )
end

function cstrEnforceUnitTurnOnCnt(min_turnons::Int)
    function _cstrEnforceUnitTurnOnCnt(model, vars, problem)
        vTurnUnitOn = vars.vTurnUnitOn

        @constraint(model, cNBUsed,
          sum(vTurnUnitOn[u, p] for u in problem.units, p in problem.periods) >= min_turnons)
    end
    _cstrEnforceUnitTurnOnCnt
end

function cstrObjective(model, vars, problem)
    vObjective = vars.vObjective
    vUnitInUse = vars.vUnitInUse
    vProduction = vars.vProduction
    vTurnUnitOn = vars.vTurnUnitOn

    @constraints(model,
    begin
        vObjective["fixed_cost"] == sum(vUnitInUse[u,p] * problem.units_properties[u]["constant_cost"] for u in problem.units, p in problem.periods)

        vObjective["variable_cost"] == sum(vProduction[u, p] * problem.units_properties[u]["linear_cost"] for u in problem.units, p in problem.periods)

        vObjective["startup_cost"] == sum(vTurnUnitOn[u, p] * problem.units_properties[u]["start_up_cost"] for u in problem.units, p in problem.periods)

        vObjective["co2_cost"] == sum(vProduction[u, p] * problem.units_properties[u]["co2_cost"]
        for u in problem.units, p in problem.periods)
    end)

    @objective(model,
        Min,
        sum(vObjective[w[1]]*w[2] for w in problem.weights)
    )
end

function _postCstr(cstr, model, vars, problem)
    num_cstrs_before = JuMP.num_constraints(model; count_variable_in_set_constraints = true)
    cstr(model, vars, problem)
    num_cstrs_after = JuMP.num_constraints(model; count_variable_in_set_constraints = true)
    @info "$(cstr) created $(num_cstrs_after - num_cstrs_before) constraints"
end
