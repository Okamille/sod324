# using CPLEX
# using GLPK
# using Cbc
using Clp
using JuMP

include("seqata_test_model_util.jl")

# ===========
# Préparartion des arguments
args = Args.parse_commandline()
const TEST_LEVEL = 1 
Args.set(:level, TEST_LEVEL) # sera passé temporairement à 0
Args.set(:outdir, "/tmp") # eqivalent à  -d/tmp
Args.set(:itermax, 300)

# ===========
inst = instance_build_mini10()
@test inst.nb_planes == 10

# Création d'une struct encapsulant la spécifiation d'un test LP
specs = [
   LpSolverSpec(:lp,  :clp, LpTimingSolver,  Clp.Optimizer),
#    LpSolverSpec(:lp2, :clp, Lp2TimingSolver, Clp.Optimizer),
#    LpSolverSpec(:lp3, :clp, Lp3TimingSolver, Clp.Optimizer),
#    LpSolverSpec(:lp4, :clp, Lp4TimingSolver, Clp.Optimizer),
]

for spec in specs
    test_name = "Test descente LP $(spec.algo):$(spec.external_mip_solver)"
    lg1("$test_name ... ")
    @testset "$test_name" begin
        Args.set(:level, 0)
        test_one_lp_descent(spec)
        Args.set(:level, TEST_LEVEL)
    end
    ln1(" => fait.")
end
