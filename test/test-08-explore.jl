include("../src/solution.jl")
include("../src/solvers/explore.jl")

# ===========
# Préparartion des arguments
args = Args.parse_commandline("explore")
const TEST_LEVEL = 1 
Args.set(:level, TEST_LEVEL) # sera passé temporairement à 0
# Args.set(:itermax, 1_000) # Inutile pour ExploreSolver
# itermax = Args.get(:itermax)

# ===========
# Construction de l'instance mini
inst = instance_build_mini10()
@test inst.nb_planes == 10


# ===========
lg1("1. Création d'un ExploreSolver... ")
# Args.set(:level, 0)
# Args.show_args()
solver = ExploreSolver(inst)
# println(Args.to_s_dict(Args.args))
# shuffle!(solver.cursol)
ln1("fait.")


# ===========
lg1("2. Mélange de la solution initiale... ")
initial_sort!(solver.cursol, presort=:shuffle)
copy!(solver.bestsol, solver.cursol)
ln1(" => (initcost=$(solver.cursol.cost)) fait")


# ===========
itermax = 10_000
lg1("3. Résolution avec itermax=$itermax) itérations ")
lg1("(cost=700 <= 5500.0 ?)... ")
# solve(solver, Args.get(:itermax))
Args.set(:level, 0)
solve(solver, itermax, small_shift!)
Args.set(:level, TEST_LEVEL)
bestsol = solver.bestsol
@test bestsol.cost <= 5500.0
ln1(" => ok ($(bestsol.cost))")

# ===========
itermax = 100_000
lg1("4. Résolution avec itermax=$itermax) itérations supplémentaires")
lg1("(cost=700 <= 5500.0 ?)... ")
# solve(solver, Args.get(:itermax))
Args.set(:level, 0)
solve(solver, itermax, swap!)
Args.set(:level, TEST_LEVEL)
bestsol = solver.bestsol
@test bestsol.cost <= 5500.0
ln1(" => ok ($(bestsol.cost))\n")

#./