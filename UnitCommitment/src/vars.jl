struct UCVars
    vUnitInUse
    vTurnUnitOn
    vTurnUnitOff
    vProduction
    vExchange
    vObjective

    function UCVars(problem::Problem, model::JuMP.Model)
        new(
            @variable(model, vUnitInUse[problem.units, problem.periods], Bin),
            @variable(model, vTurnUnitOn[problem.units, problem.periods], Bin),
            @variable(model, vTurnUnitOff[problem.units, problem.periods], Bin),
            @variable(model, vProduction[problem.units, problem.periods] >=0),
            @variable(model, vExchange[problem.periods] >=0),
            @variable(model, vObjective[keys(problem.weights)] >=0)
        )
    end
end
