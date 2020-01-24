@ms include("solvers/annealing.jl")

function loop_annealing(args)
    # Résolution de l'action
    println("="^70)
    instances = [
        "01",
        "02",
        "03",
        "04",
        "05",
        "06",
        "07",
        "08",
        "09",
        "10",
        "11",
        "12",
        "13"
    ]
    for instance_name in instances
        println("Recuit: instance $instance_name")
        instance_path = "data/$instance_name.alp"
        inst = Instance(instance_path)

        sol = Solution(inst)
        # ln1("Solution correspondant à l'ordre de l'instance")
        # ln1(to_s(sol))
    
        # # ON POURRAIT AUSSI REPARTIR DE LA SOLUTION DU GLOUTON INTELLIGENT 
        initial_sort!(sol)
        # ln1("Solution initiale envoyée au solver")
        # ln1(to_s(sol))

        sv = AnnealingSolver(
            inst; 
            temp_init_rate=0.3,
            step_size=inst.nb_planes,
            startsol=sol,
            temp_coef=0.999_95
        )
        ln1(get_stats(sv))

        ms_start = ms() # nb secondes depuis démarrage avec précision à la ms
        costs = solve(sv, swap_operator!, durationmax=15*60)
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
end

loop_annealing(Args.args)