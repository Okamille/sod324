using CPLEX
# using GLPK
# using Cbc
using JuMP

include("seqata_test_model_util.jl")
include("../src/solvers/mip.jl")

# ===========
# Préparartion des arguments
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
# Les solvers à tester
specs = [
  # LpSolverSpec(:lp,    :cbc,   LpTimingSolver, Cbc.Optimizer),
  LpSolverSpec(:lp,  :cplex,   LpTimingSolver, CPLEX.Optimizer),
  # LpSolverSpec(:lp,   :glpk,   LpTimingSolver, GLPK.Optimizer),
]
spec = specs[1]


# ===========
lg1("1. Création d'un MipSolver pour $(spec.external_mip_solver)... ")
Args.set("external_mip_solver", spec.external_mip_solver)

Args.set(:level, 0)
solver = MipSolver(inst)
Args.set(:level, TEST_LEVEL)

# Introspection du solveur interne à JuMP (délicat et peu robuste)
#
# Pourquoi il faut prendre ici "optimizer.model.optimizer" contrairement au
# test-04c-descent-lp-xxx.jl qui demande simplement "optimizer.model" ??
# 
# backend_model = JuMP.backend(solver.mip_model).optimizer.model # PLANTE
# 
# Pour debug : contenu complet de l'objet model JuMP
#   dump(JuMP.backend(solver.mip_model))
#
# Pour debug : contenu complet de l'objet optimizer interne à JuMP
#   dump(JuMP.backend(solver.mip_model).optimizer.model)

backend_model = JuMP.backend(solver.mip_model).optimizer.model
# backend_model = JuMP.backend(solver.mip_model).optimizer.model.optimizer


# On s'assure que le solver utilisé est bien celui spécifié
@test typeof(backend_model) == spec.backend_model
ln1("fait.")

# ===========
lg1("2. Résolution par MipSolver (cost=700.0 ?)... ")

Args.set(:level, 0)
solve(solver)
Args.set(:level, TEST_LEVEL)

bestsol = solver.bestsol
@test bestsol.cost == 700.0

ln1("(cost=$(solver.bestsol.cost)) ok\n")
