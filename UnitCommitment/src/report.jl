using Weave

function generate_report(report_jmd::String, report_html::String, demand_aug_ratio::Float64, solution::Solution, metrics)
    @info "Generating report using $(report_jmd) into $(report_html)"
    println(pwd())
    ENV["GKSwstype"]="nul"
    Weave.weave(
        report_jmd,
        out_path=report_html,
        doctype="md2html",
        args=(demand_aug_ratio = demand_aug_ratio, metrics=metrics, solution=solution))

end
