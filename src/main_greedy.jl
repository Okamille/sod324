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
        x[i] = max(arrivals[i], x[i - 1] + sep[i-1]) #dans l'idéal il faudrait boucler sur TOUS les avions précédant i, car on peut respecter la distance avec i-1 mais pas i-2 par exemple
    end

    println(x)

    println("Fin de l'action greedy")

    # Calcul du cout

    cost = 0

    costvect = zeros(n)
    for i=1:n
        delta = x[i] - arrivals[i] # positive if lands later than expected
        costvect[i] = 10 * min(delta,0) + 30 * max(delta,0) #pénalité de 10 par unité d'avance, 30 par unité de retard
        cost = cost + costvect[i]
    end

    #Création du fichier solution 

    solfilepath = string("$APPDIR/sols/",instance.name,"=",cost,".sol")
    println(solfilepath)
    io = open(solfilepath, "w")

    # Remplissage du fichier solution 

    println(io,string("name ",instance.name))#,"\n"))
    #pas besoin de sauter de ligne, c'est automatique lorsque l'on fait un nouveau println
    println(io,string("timestamp ",Dates.DateTime(now())))
    println(io,string("cost ", cost))
    println(io,string("order ",planes))
    println(io,"")
    println(io,"#       name     t   dt  cost ")#       # comments")

    # boucle for sur les avions

    for i = 1:n
        println(io,string(
        "landing     ",planes[i]," ",x[i]," ",x[i]-arrivals[i]," ",costvect[i]," "
        ))
    end

    close(io)
    
end

main_greedy(Args.args)
