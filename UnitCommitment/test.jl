include("src/UnitCommitment.jl")
using HiGHS
using GLPK
using Cbc
using JuMP

backends = Dict(
        "highs" => optimizer_with_attributes(
                HiGHS.Optimizer,
                "presolve" => "on",
                "mip_heuristic_effort" => 0.05,
                "simplex_strategy" => 0,
                "mip_report_level" => 2),

        "glpk" => optimizer_with_attributes(
                        GLPK.Optimizer,
                        "fp_heur" => GLPK.GLP_ON,
                        # "ps_heur" => GLPK.GLP_ON,
                        "presolve" => GLPK.GLP_ON,
                        "msg_lev" => GLPK.GLP_MSG_ON),
        "cbc" => Cbc.Optimizer
)

function run(backend::String="highs")
    @info "Using $backend as optimizer"
    uc=UnitCommitment
    p = uc.load_data(
            "data/Loads.csv",
            "data/Units.csv",
            "data/UnitMaintenances.csv",
            "data/Exchanges.csv",
            "data/Weights.csv")
    m = uc.build_model(backends[backend], p)
    s = uc.solve(m)

    e = uc.evaluate(s)
    uc.to_json(e, "metrics.json")

    # Weave executes in output path dir
    UnitCommitment.generate_report(
        "UnitCommitment/report.jmd",
        "report.html",
        1.2,
        s,
        "metrics.json")
end
