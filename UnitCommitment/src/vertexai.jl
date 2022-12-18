module VertexAI

using PyCall

struct Executor
    pyexecutor
    pymetrics
    report

function Executor(input::String)
    pyjson = pyimport("json")
    pyexecutor = pyimport("kfp.v2.components.executor")

    pyidfun = py"lambda x: x"

    executor_input = pyjson.loads(input)
    executor = pyexecutor.Executor(executor_input, pyidfun)
    # py"""
    # import json
    # from kfp.v2.components.executor import Executor
    # executor_input = json.loads($(input))
    # executor = Executor(executor_input, lambda x: x)
    # """

    new(
        executor,
        executor._get_output_artifact("metrics"),
        executor._get_output_artifact("report")
    )
end

end

function input_artifacts(executor::Executor)
    executor.pyexecutor._input_artifacts
end

function output_artifacts(executor::Executor)
    executor.pyexecutor._output_artifacts
end

function output_artifact(executor::Executor, key::String)
    executor.pyexecutor._get_output_artifact(key)
end

function input_artifact(executor::Executor, key::String)
    executor.pyexecutor._get_input_artifact(key)
end

function output_artifact_path(executor::Executor, key::String)
    executor.pyexecutor._get_output_artifact_path(key)
end

function input_artifact_path(executor::Executor, key::String)
    executor.pyexecutor._get_input_artifact_path(key)
end

function log_metric(executor::Executor, metric::String, value::T) where {T <: AbstractFloat}
    executor.pymetrics.log_metric(metric, value)
end

function write_output(executor::Executor)
    executor.pyexecutor._write_executor_output()
end


end
