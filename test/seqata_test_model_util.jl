include("../src/model_util.jl")
include("../src/solvers/descent.jl")
include("../src/solvers/lp_timing.jl")
# include("../src/solvers/lp2_timing.jl")
# include("../src/solvers/lp3_timing.jl")
# include("../src/solvers/lp4_timing.jl")

# Création d'une struct encapsulant la spécification d'un test LP
struct LpSolverSpec
    algo::Union{Symbol,Nothing}
    external_mip_solver::Union{Symbol,Nothing}
    lp_timing_solver::Union{DataType,Nothing}
    backend_model::Union{DataType,Nothing}
end

function test_one_lp_descent(spec)

    
    # ===========
    ln2("Création sol avec algo ")
    lg2(spec.algo, ":", spec.external_mip_solver)
    lg2(" (", spec.lp_timing_solver, "... ")
    Args.set(:external_mip_solver, spec.external_mip_solver)
    sol = Solution(inst, algo=spec.algo)
    model = sol.solver.mip_model
    initial_sort!(sol, presort=:shuffle)


    @test isa(sol.solver, spec.lp_timing_solver)
    # On vérifie par exemple que le nom du solver externe "Clp" effectif 
    # correspondant bien au symbole :clp du solveur demandé
    @test Symbol(lowercase(solver_name(model))) == spec.external_mip_solver
    lg2("ok (avec sol.cost=$(sol.cost))\n")


    # ===========
    lg2("Création DescentSolver nb_cons_reject_max=$(Args.get(:itermax))")
    lg2(" (cost=700<=850.0?)... ")
    sv = DescentSolver(inst)
    # println("\nconstruction faite")
    sv.do_save_bestsol = false
    sv.nb_cons_reject_max = Args.get(:itermax) # Devra être écrasé
    sv.durationmax = 1                         # Devra être écrasé
    # solve(sv, startsol=sol, nb_cons_reject_max=Args.get(:itermax))
    # Args.set(:level, 3)
    solve(sv, startsol=sol, nb_cons_reject_max=200, durationmax=3)
    # println("\nrésolution faite")
    @test sv.durationmax == 3
    @test sv.nb_cons_reject_max == 200
    @test isa(sv.bestsol.solver, spec.lp_timing_solver)
    # @test sv.bestsol.cost <= 850.0
    # @test sv.bestsol.cost <= 900.0
    # @test sv.bestsol.cost >= 700.0
    @test 700 <= sv.bestsol.cost <= 1_000.0
    lg1("ok ($(sv.bestsol.cost))\n")

end
