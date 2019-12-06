# using CPLEX
# using GLPK
using Cbc
using JuMP

include("seqata_test_model_util.jl")
include("../src/mip_discret_solver.jl")

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
lg1("1. Création d'un MipDiscretSolver pour Cbc... ")
Args.set("external_mip_solver", :cbc)
Args.set(:level, 0)
solver = MipDiscretSolver(inst)
Args.set(:level, TEST_LEVEL)
# @test typeof(solver.mip_model.solver) ==
#       Cbc.CbcMathProgSolverInterface.CbcSolver
backend_model = JuMP.backend(solver.mip_model).optimizer.model.optimizer # SPECIAL CBC
# dump(JuMP.backend(solver.mip_model).optimizer.model)
@test typeof(backend_model) == Cbc.Optimizer
ln1(" fait.")

# ===========
lg1("2. Résolution par MipDiscretSolver pour Cbc (cost=700.0 ?) LONG (80s+) ... ")
solve(solver)
bestsol = solver.bestsol
# @test bestsol.cost == 700.0
@test isapprox(bestsol.cost, 700.0) # approx car cbc trouve 699.999999999996
ln1(" (cost=$(solver.bestsol.cost)) fait.\n")
