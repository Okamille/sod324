@ms include("solvers/annealing.jl")

function loop_annealing(args)
    instances = [
        # "02",
        # "03",
        # "05",
        # "08",
        # "09",
        # "10",
        # "11",
        "12",
        # "13"
    ]
    println("Instance n° & Cost & Time")
    for instance_name in instances
        instance_path = "data/$instance_name.alp"
        inst = Instance(instance_path)
        sol = Solution(inst)

        initial_sort!(sol)

        sv = AnnealingSolver(
            inst; 
            temp_init_rate=0.8,
            step_size=1,
            startsol=sol,
            temp_coef=0.985,
            nb_cons_reject_max=1_000_000_000,
            nb_cons_no_improv_max=1_000_000_000
        )

        ms_start = ms() # nb secondes depuis démarrage avec précision à la ms
        costs = solve(sv, swap_close_planes!, durationmax=3*60*60)
        ms_stop = ms()

        bestsol = sv.bestsol

        nb_calls = bestsol.solver.nb_calls
        nb_infeasable = bestsol.solver.nb_infeasable
        nb_sec = round(ms_stop - ms_start, digits=3)
        nb_call_per_sec = round(nb_calls/nb_sec, digits=3)
        println("Performance: ")
        println("  nb_calls=$nb_calls")
        println("  nb_infeasable=$nb_infeasable")
        println("  nb_sec=$nb_sec")
        println("  => nb_call_per_sec = $nb_call_per_sec call/sec")
        println("$instance_name & $(bestsol.cost) & $nb_sec")
        end
end

loop_annealing(Args.args)
