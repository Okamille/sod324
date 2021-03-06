include("solvers/annealing.jl")

function main_annealing(args)
    ln1("="^70)
    ln1("Début de l'action annealing")
    inst = Instance(args[:infile])

    # Construction de la solution initiale :
    sol = Solution(inst)
    ln1("Solution correspondant à l'ordre de l'instance")
    ln1(to_s(sol))

    initial_sort!(sol)
    ln1("Solution initiale envoyée au solver")
    ln1(to_s(sol))

    sv = AnnealingSolver(
        inst; 
        temp_init_rate=0.8,
        step_size=1,
        startsol=sol,
        temp_coef=0.985,
    )
    ln1(get_stats(sv))

    ms_start = ms()
    solve(sv, swap_close_planes!, durationmax=15*60)
    ms_stop = ms()

    bestsol = sv.bestsol
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

    ln1("Fin de l'action annealing")
end

main_annealing(Args.args)
