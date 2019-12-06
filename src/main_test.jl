# include("taboo_solver.jl")

# Cette action est destinée à la mise au point de code (nouveau solveurs,
# nouveaux voisinages, ...) 
# Une fois la fonctionnalité opérationnel, il faut en faire en test unitaire
# (i.e. en créant un nouveau fichier dans tests/text_xxx.jl)
function main_test(args)
    # p1 = Plane("p2", 1, 100, 150, 200, 1.0, 2.0)
    # p2 = Plane("p22", 1, 100, 150, 200, 1.0)

    if Args.get(:infile) == "NO_INFILE"
        Args.set(:infile, "data/alpx/01.alpx")
    end
    println("="^70)
    println("Début de l'action test")
    inst = Instance(Args.get(:infile))

    sol = Solution(inst)
    println(to_s(sol)) # OK
    solve!(sol)
    println(to_s(sol)) # OK
    Random.shuffle!(sol.planes)
    println(to_s(sol)) # OK
    solve!(sol)
    println(to_s(sol)) # OK

    println("Fin de l'action test")
end

try
    main_test(Args.args)
catch e
    println(join(stacktrace(), "\n\n"))
    println("\nERREUR: relancer main_test")
end