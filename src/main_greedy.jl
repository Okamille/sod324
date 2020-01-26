@ms include("instance.jl")
@ms include("solvers/greedy.jl")

function main_greedy(args)
    println("="^70)
    println("Début de l'action greedy")

    filename = args[:infile]
    instance = Instance(filename)
    solution = Solution(instance)

    ms_start = ms()
    # initial_sort!(solution)
    greedy!(solution)
    ms_stop = ms()
    nb_sec = round(ms_stop - ms_start, digits=3)
    print_sol(solution)
    println("Fin de l'algorithme glouton")
end

main_greedy(Args.args)
