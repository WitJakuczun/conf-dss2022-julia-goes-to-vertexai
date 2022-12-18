include("vars.jl")
include("constraints.jl")
struct UCModel
    model::JuMP.Model
    problem::Problem
    vars::UCVars

    function UCModel(backend, _problem::Problem, cstrs)
        model = JuMP.Model(backend)
        vars = UCVars(_problem, model)

        @info "Created $(num_variables(model)) variables."

        for cstr in cstrs
            _postCstr(cstr, model, vars, _problem)
        end

        new(model,
            _problem,
            vars
        )
    end
end

function build_model(backend, problem::Problem, cstrs = nothing)
    if cstrs === nothing
        cstrs = [
            cstrRampUpDown,
            cstrInitialState,
            cstrMinMaxGeneration,
            cstrTurnUnitOnOff,
            cstrMinUpDownTime,
            cstrDemandEnforce,
            cstrMaxEchange,
            cstrUnitMaintenance,
            cstrObjective,
            cstrEnforceUnitTurnOnCnt(0)
        ]
    end

    UCModel(backend, problem, cstrs)
end
