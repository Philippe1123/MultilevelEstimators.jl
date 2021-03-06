using Documenter, MultilevelEstimators

makedocs(modules = [MultilevelEstimators],
		 sitename = "MultilevelEstimators.jl",
         format = Documenter.HTML(
                                  prettyurls = false,#!("local" in ARGS),
                                 ),
         authors = "Pieterjan Robbe",
         pages = Any[
                  "Home" => "index.md",
                  "Example" => "example.md",
                  "Manual" => "manual.md",#["Index" => "index.md",
                              # "IndexSet" => "index_set.md",
                              # "SampleMethod" => "sample_method.md",
                              # "Distribution" => "distribution.md",
                              # "Estimator" => "estimator.md",
                              # "History" => "history.md"
                              #]
                 ]
         )

deploydocs(
    repo = "github.com/PieterjanRobbe/MultilevelEstimators.jl.git",
)
