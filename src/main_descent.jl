@ms include("solvers/descent.jl")

function main_descent(args)
    # Résolution de l'action
    println("="^70)
    println("Début de la méthode de descente")
    inst = Instance(args[:infile])
    sol = Solution(inst)

    initial_sort!(sol)

    sv = DescentSolver(inst)

    duration = 15*60 # secondes
    itermax = Args.get(:itermax)

    ms_start = ms()
    solve(sv, swap_close_planes!, durationmax=duration,
          startsol=sol)
    ms_stop = ms()

    bestsol = sv.bestsol
    write(bestsol)
    print_sol(bestsol)

    nb_calls = bestsol.solver.nb_calls
    nb_infeasable = bestsol.solver.nb_infeasable
    nb_sec = round(ms_stop - ms_start, digits=3)
    nb_call_per_sec = round(nb_calls/nb_sec, digits=3)
    println("Performance: ")
    println("  nb_calls=$nb_calls")
    println("  nb_infeasable=$nb_infeasable")
    println("  nb_sec=$nb_sec")
    println("  => nb_call_per_sec = $nb_call_per_sec call/sec")
end

main_descent(Args.args)
