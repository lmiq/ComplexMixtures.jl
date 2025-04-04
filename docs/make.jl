import Pkg
Pkg.add("Documenter")
using ComplexMixtures
using Documenter
using ComplexMixtures
push!(LOAD_PATH,"../src/")
makedocs(
    modules=[ComplexMixtures],
    sitename="ComplexMixtures.jl",
    pages = [
        "Introduction" => "index.md",
        "Installation" => "installation.md",
        "Parallel execution" => "parallel.md",
        "Quick Guide" => "quickguide.md",
        "Full Example" => "examples.md",
        "Set solute and solvent" => "selection.md",
        "Loading the trajectory" => "trajectory.md",
        "Computing the MDDF" => "mddf.md",
        "Results" => "results.md",
        "Atomic and group contributions" => "contrib.md",
        "Save and load" => "save.md",
        "Multiple trajectories" => "multiple.md",
        "Options" => "options.md",
        "Tools" => "tools.md",
        "Help entries" => "help.md",
        "References" => "references.md"
    ]
)
deploydocs(
    repo = "github.com/m3g/ComplexMixtures.jl.git",
    target = "build",
    branch = "gh-pages",
    versions = ["stable" => "v^", "v#.#" ],
)
