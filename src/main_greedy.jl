@ms include("instance.jl")

function main_greedy(args)
    println("="^70)
    println("Début de l'action greedy")

    filename = args[:infile]

    # println("Action greedy non implanté : AU BOULOT :-)")
    # exit(1)
    # error("\n\nAction greedy non implanté : AU BOULOT :-)\n\n")
    instance = Instance(filename)
    n = instance.nb_planes
    planes = instance.planes

    arrivals = zeros(n)
    departs = zeros(n)

    for i = 1:n
        plane = planes[i]
        arrivals[i] = plane.lb
        departs[i] = plane.ub
    end

    perm = sortperm(arrivals)
    planes = planes[perm]

    arrivals = arrivals[perm]
    departs = departs[perm]

    sep = zeros(n-1)
    for i = 1:n-1
        sep[i] = get_sep(instance, planes[i], planes[i+1])
    end

    println(arrivals)
    println(sep)

    x = zeros(Int, n)
    x[1] = arrivals[1]

    for i=2:n
        # dans l'idéal il faudrait boucler sur TOUS les avions précédant i,
        # car on peut respecter la distance avec i-1 mais pas i-2 par exemple
        x[i] = max(arrivals[i], x[i - 1] + sep[i-1])
    end

    solution = Solution(instance, planes, x)
    write(solution)
    print_sol(solution)
    println("Fin de l'algorithme glouton")
end

main_greedy(Args.args)
