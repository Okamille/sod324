
include("../src/solvers/descent.jl")
# include("../src/solvers/faye_timing.jl")
# include("../src/solvers/dynprog_timing.jl")
include("../src/solvers/earliest_timing.jl")
include("../src/solvers/lp_timing.jl")


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


# ===========
lg1("1. Création sol avec args :lp... ")
# Args.set(:timing_algo_solver, :earliest)
Args.set(:timing_algo_solver, :lp)

Args.set(:level, 0)
sol = Solution(inst)
Args.set(:level, TEST_LEVEL)

@test Args.get("timing_algo_solver") == :lp
@test sol.timing_algo_solver == :lp
@test isa(sol.solver, LpTimingSolver)

@test sol.cost == 25650.0 # pour LpTimingSolver
# @test sol.cost == 25910.0 # pour EarliestTimingSolver

ln1("fait.")

# ===========
lg1("2. Création sol avec args :lp mais construite avec :earliest ... ")
# Args.set(:timing_algo_solver, :earliest)
Args.set(:timing_algo_solver, :lp)

sol = Solution(inst, algo=:earliest)

@test Args.get("timing_algo_solver") == :lp
@test sol.timing_algo_solver == :earliest
@test isa(sol.solver, EarliestTimingSolver)

# @test sol.cost == 25650.0 # pour LpTimingSolver
@test sol.cost == 25910.0 # pour EarliestTimingSolver

ln1("fait.")

# ===========
lg1("3. Création sol avec args :earliest... ")
Args.set(:timing_algo_solver, :earliest)

sol = Solution(inst)

@test Args.get("timing_algo_solver") == :earliest
@test sol.timing_algo_solver == :earliest
@test isa(sol.solver, EarliestTimingSolver)


# @test sol.cost == 25650.0 # pour LpTimingSolver
@test sol.cost == 25910.0 # pour EarliestTimingSolver

ln1("fait.")

# ===========
lg1("4. Création d'une sol alp01 aléatoire avec algo :earliest... ")
sol = Solution(inst, algo=:earliest)
# initial_sort!(solver.cursol, presort=:shuffle)
initial_sort!(sol, presort=:shuffle)
# @test sol.solver == nothing
@test sol.timing_algo_solver == :earliest
@test isa(sol.solver, EarliestTimingSolver)
# copy!(solver.bestsol, solver.cursol)
ln1("(sol.cost=$(sol.cost)) fait.")

# ===========
lg1("5. Création DescentSolver nb_cons_reject_max=$(Args.get(:itermax)) ")
ln1("(cost=700<=1000.0 ?)... ")
sv = DescentSolver(inst, startsol=sol)
sv.do_save_bestsol = false
sv.nb_cons_reject_max = 1000
sv.durationmax = 1
# Args.set(:level, 3)

Args.set(:level, 0)
solve(sv, startsol=sol, nb_cons_reject_max=300, durationmax=3)
Args.set(:level, TEST_LEVEL)

@test sv.durationmax == 3
@test sv.nb_cons_reject_max == 300
# @show typeof(sv.bestsol.solver)
# @show sv.bestsol.solver
@test typeof(sv.bestsol.solver) == EarliestTimingSolver
@test sv.bestsol.cost <= 2500.0 # 2110
@test sv.bestsol.cost >= 2110.0
ln1("   => fait : trouvé $(sv.bestsol.cost) (au lieu de 2110*))")
ln1("      ", to_s(sv.bestsol), "\n")
