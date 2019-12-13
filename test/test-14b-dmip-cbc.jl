# using CPLEX
# using GLPK
using Cbc
using Clp
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
lg1("1. Création d'un MipDiscretSolver pour Cbc... ")
Args.set("external_mip_solver", :cbc)
Args.set(:level, 0)
solver = MipDiscretSolver(inst)
Args.set(:level, TEST_LEVEL)

# Le nom du solver Cbc n'est pas standard :
#   @show solver_name(solver.model)
#   => "COIN Branch-and-Cut (Cbc)"
# Donc ceci ne fonctionne pas :
#   @test Symbol(lowercase(solver_name(solver.model))) == :cbc
# Je teste alors la présence de la sous-chaine cbs
@test occursin("cbc", lowercase(solver_name(solver.model)))

ln1(" fait.")

# ===========
lg1("2. Résolution par MipDiscretSolver pour Cbc (cost=700.0 ?) LONG (9mn+) ... ")
solve(solver)
bestsol = solver.bestsol
# @test bestsol.cost == 700.0
@test isapprox(bestsol.cost, 700.0) # approx car cbc trouve 699.999999999996
ln1(" (cost=$(solver.bestsol.cost)) fait.\n")
