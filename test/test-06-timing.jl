using CPLEX
using GLPK
using Cbc
using Clp
using JuMP

include("../src/utils/model.jl")
# include("../src/solvers/mip.jl")
include("../src/solvers/lp_timing.jl")
include("../src/solvers/earliest_timing.jl")

# EXEMPLE DE LIGNE DE COMMANDE TESTÉE :
# ./bin/seqata.jl val -i data/ampl/01.ampl -p 3,4,5,6,7,8,9,1,10,2 -x clp
#

# ===========
# Préparation des arguments
args = Args.parse_commandline()
const TEST_LEVEL = 1 
Args.set(:level, TEST_LEVEL) # sera passé temporairement à 0
Args.set(:outdir, "/tmp") # equivalent à l'option -d/tmp

# ===========
# Construction de l'instance mini
inst = instance_build_mini10()
@test inst.nb_planes == 10


# ==========
# Ordre des avions à tester
planes_str = "p3,p4,p5,p6,p7,p8,p9,p1,p10,p2"
# planes = matchall(r"[\w]+", planes_str)
# planes = collect( (m.match for m = eachmatch(r"[\w]+", planes_str) ))
planes = [ m.match for m = eachmatch(r"[\w]+", planes_str) ]

test_name = "Création et résolution du timing d'une solution pour algo :earliest"
lg1(test_name, "... ")
@testset "$test_name" begin

      sol = Solution(inst, update=false, algo=:earliest)

      @test isa(sol.solver, EarliestTimingSolver)
      # Random.shuffle!(sol.planes); solve!(sol)
      shuffle!(sol, do_update=true)
      @test sol.cost > 1000.0  # cost >> 700 si mélange presque surement

      # On impose l'ordre des avions comme souhaité
      set_from_names!(sol, planes)

      # On doit retrouver cet ordre dans la solution
      @test join(get_names(sol), ",") == planes_str

      # On résout le sous-problème de timing de cette solution
      solve!(sol)
      # @test sol.cost == 700.0 # avec :lp
      @test sol.cost == 2830.0 # avec :earliest

end
ln1(" fait.")


# ====================================================================
test_name = "Création et résolution du timing d'une solution pour algo :lp avec :cplex"
print(test_name, "... ")
@testset "$test_name" begin

      Args.set("timing_algo_solver", :lp)
      Args.set("external_mip_solver", :cplex)
      # Args.set("planes", planes_str) # idem que l'option -p


      # sol = Solution(inst, update=false, algo=:lp)
      sol = Solution(inst, update=false)   # alpo=:lp par défaut
      @test isa(sol.solver, LpTimingSolver)

      backend_model = JuMP.backend(sol.solver.mip_model).optimizer.model
      @test typeof(backend_model) ==  CPLEX.Optimizer

      # On mélange les avions puis on met à jour la solution
      # print("Mélange et évaluation de la solution (cos>1000 ?)...")
      shuffle!(sol, do_update=true)
      @test sol.cost > 1000.0  # cost >> 700 car mélange presque surement

      # On impose l'ordre des avions comme souhaité
      set_from_names!(sol, planes)

      # On doit retrouver cet ordre dans la solution
      @test join(get_names(sol), ",") == planes_str

      # On résout le sous-problème de timing de cette solution
      solve!(sol)
      @test sol.cost == 700.0
end
ln1(" fait.")


# ====================================================================
test_name = "Création et résolution du timing d'une solution pour algo :lp avec :clp"
lg1(test_name, "... ")
@testset "$test_name" begin
      Args.set("external_mip_solver", :clp)
      sol = Solution(inst, update=false, algo=:lp)

      @test isa(sol.solver, LpTimingSolver)
      
      # CE TEST INTERNE NE FONCTIONNE PLUS AVEC JuMP-0.20.1 => A CORRIGER
      # backend_model = JuMP.backend(sol.solver.mip_model).optimizer.model
      # @test typeof(backend_model) ==  Clp.Optimizer
      # # @test typeof(sol.solver.mip_model.solver) ==
      # #       GLPKMathProgInterface.GLPKInterfaceLP.GLPKSolverLP


      shuffle!(sol, do_update=true)
      @test sol.cost > 1000.0  # cost >> 700 si mélange presque surement

      # On impose l'ordre des avions comme souhaité
      set_from_names!(sol, planes)

      # On doit retrouver cet ordre dans la solution
      @test join(get_names(sol), ",") == planes_str

      # On résout le sous-problème de timing de cette solution
      solve!(sol)
      @test sol.cost == 700.0

end
ln1(" fait.\n")
