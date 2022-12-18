module UnitCommitment

using ArgParse
using Cbc
using GLPK
using HiGHS
using CSV
using DataFrames
using JSON
using JuMP
using Logging

include("data.jl")
include("model.jl")
include("solver.jl")
include("evaluate.jl")
include("report.jl")

include("vertexai.jl")
const vai=VertexAI

function parse_cmdline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--demand-aug-ratio"
            help = "How much augment demand"
            arg_type = Float64
        "--executor-input"
            help = "VertexAI Executor input"
            arg_type = String
    end

    return parse_args(s)
end

function main()
    @info ">>> Julia"

    args = parse_cmdline()

    executor = vai.Executor(args["executor-input"])

    @info "Loading parameters and input data"
    problem = load_data(
        vai.input_artifact_path(executor, "loads"),
        vai.input_artifact_path(executor, "units"),
        vai.input_artifact_path(executor, "units-maintenance"),
        vai.input_artifact_path(executor, "exchanges"),
        vai.input_artifact_path(executor, "weights"))

    @info "Solving UC problem"
    model = build_model(HiGHS.Optimizer, problem)

    solution = solve(model)
    metrics = evaluate(solution)

    @info "Log metrics into VertexAI"
    for mv in to_dict(metrics)
        vai.log_metric(executor, mv[1], mv[2])
    end

    @info "Generating report"
    generate_report(
        "UnitCommitment/report.jmd",
        vai.output_artifact_path(executor, "report"),
        args["demand-aug-ratio"],
        solution,
        to_dict(metrics))

    @info "Writing Executor output."
    vai.write_output(executor)
end
end # module UnitCommitment
