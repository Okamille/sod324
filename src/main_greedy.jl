@ms include("instance.jl")
@ms include("solvers/greedy.jl")

function main_greedy(args)
    println("="^70)
    println("Début de l'action greedy")

    filename = args[:infile]
    instance = Instance(filename)

    solution = greedy(instance)
    print_sol(solution)
    println("Fin de l'algorithme glouton")
end

main_greedy(Args.args)
