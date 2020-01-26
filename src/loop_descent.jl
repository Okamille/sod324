@ms include("solvers/descent.jl")

function loop_descent(args)
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

        sv = DescentSolver(inst)

        duration = 6*60*60 # secondes
        itermax = Args.get(:itermax)

        ms_start = ms()
        solve(sv, swap_close_planes!, durationmax=duration,
              nb_cons_reject_max=itermax,
              startsol=sol)
        ms_stop = ms()

        bestsol = sv.bestsol

        nb_calls = bestsol.solver.nb_calls
        nb_infeasable = bestsol.solver.nb_infeasable
        nb_sec = round(ms_stop - ms_start, digits=3)
        nb_call_per_sec = round(nb_calls/nb_sec, digits=3)
        # println("Performance: ")
        # println("  nb_calls=$nb_calls")
        # println("  nb_infeasable=$nb_infeasable")
        # println("  nb_sec=$nb_sec")
        # println("  => nb_call_per_sec = $nb_call_per_sec call/sec")
        println("$instance_name & $(bestsol.cost) & $nb_sec")
    end
end

loop_descent(Args.args)
