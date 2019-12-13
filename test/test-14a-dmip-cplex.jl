using CPLEX
# using GLPK
# using Cbc
using JuMP

include("seqata_test_model_util.jl")
include("../src/solvers/mip_discret.jl")

# ===========
# Préparation des arguments
args = Args.parse_commandline()
const TEST_LEVEL = 1 
Args.set(:level, TEST_LEVEL) # sera passé temporairement à 0
Args.set(:itermax, 300)
Args.set(:outdir, "/tmp") # equivalent à l'option -d/tmp

# ===========
# Construction de l'instance mini
inst = instance_build_mini10()
@test inst.nb_planes == 10

# ===========
lg1("1. Création d'un MipDiscretSolver pour CPLEX... ")
Args.set("external_mip_solver", :cplex)
Args.set(:level, 0)
solver = MipDiscretSolver(inst)
Args.set(:level, TEST_LEVEL)

# backend_model = JuMP.backend(solver.model).optimizer.model
# @test typeof(backend_model) == CPLEX.Optimizer
@test Symbol(lowercase(solver_name(solver.model))) == :cplex
ln1(" fait.")

# ===========
lg1("2. Résolution par MipDiscretSolver pour CPLEX (cost=700.0 ?)... ")
# Args.set(:level, 0)
solve(solver)
# Args.set(:level, TEST_LEVEL)
bestsol = solver.bestsol
@test bestsol.cost == 700.0
ln1(" (cost=$(solver.bestsol.cost)) fait.\n")
