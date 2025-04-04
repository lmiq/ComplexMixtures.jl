module ComplexMixtures

using Printf
using Parameters
using ProgressMeter
using Statistics
using LinearAlgebra: norm, isdiag, cross, dot
using FortranFiles
using PDBTools
using StructTypes
using JSON3
using StaticArrays
using DocStringExtensions
using TestItems

import CpuId
import ChunkSplitters
import CellListMap
using .CellListMap.PeriodicSystems
import .CellListMap.PeriodicSystems: AbstractPeriodicSystem

import Random

export Selection, Trajectory, mddf, save, load, write, Options, Result
export contrib, merge
export overview, gr, grid3D
export VMDselect

# Message for internal doc strings
const INTERNAL = "**Internal structure or function, interface may change.**"

# Module for testing
include("./Testing.jl")

# Input and Output data structures
include("./io.jl")

# Options
include("./Options.jl")

# Structures and functions to deal with the solute and solvent selections
include("./VMDselect.jl")
include("./Selection.jl")

# Structures and functions to read different types of trajectories
include("./Trajectory.jl")

# Some functions to deal with rigid body calculations
include("./rigid_body.jl")

# Structures and functions to store and report results
include("./results.jl")

# Functions to construct histograms
include("./viewmol.jl")

# Functions to compute distances
include("./minimum_distances.jl")

# Update counters routines
include("./updatecounters.jl")

# Main function
include("./mddf.jl")

# Testing function
include("./isapprox.jl")

# Tools
include("./tools/gr.jl")
include("./tools/grid3D.jl")

end # module ComplexMixtures
