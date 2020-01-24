@ms include("solvers/greedy.jl")

function loop_greedy(args)
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
    println("Instance n° & Cost & Time")
    for instance_name in instances
        instance_path = "data/$instance_name.alp"
        instance = Instance(instance_path)
        solution = Solution(instance)

        ms_start = ms()
        # initial_sort!(solution)
        greedy!(solution)
        ms_stop = ms()
        nb_sec = round(ms_stop - ms_start, digits=3)
        # println("$instance_name & $(solution.cost) & $nb_sec")
        println(solution.cost)
    end
end

loop_greedy(Args.args)
