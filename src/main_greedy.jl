@ms include("processing/instance.jl")

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

    x = zeros(n)
    x[1] = arrivals[1]

    for i=2:n
        if arrivals[i] > arrivals[i - 1] + sep[i-1]
            x[i] = arrivals[i]
        else
            x[i] = arrivals[i-1] + sep[i-1]
        end
    end

    println(x)

    println("Fin de l'action greedy")
end

main_greedy(Args.args)
