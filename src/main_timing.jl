function main_timing(args)
    println("Début de l'action timing")

    # @error "main_timing: désolé la méthode main_timing n'est pas implantée"
    # Résolution de l'action
    println("="^70)
    println("Résolution du timing pour $(args[:infile])\n")
    inst = Instance(args[:infile])
    # args.names=[1,6,8,4,12,9,11,3,10,2,19,24,20,7,5,50,15,23,18,14,13,25,17,26,
    #          43,16,44,27,32,28,22,33,29,47,34,48,49,46,38,35,45,39,31,40,36,30,42,41,37,21]
    # args.names = %w(3 4 5 6 8 9 7 1 10 2)
    # puts inst.to_s
    if inst.nb_planes != length(args[:planes])
        println("\nERREUR taille (=$(inst.nb_planes) de l'instance différente ")
        println(" de la taille (=$(length(args[:planes])) de la solution")
        println()
        exit(1)
    end
    sol = Solution(inst, update=false)
    set_from_names!(sol, args[:planes])

    solve!(sol, do_update_cost=true)
    print_sol(sol)

    lg1("Création du fichier \"$(guess_solname(sol))\"... ")
    write(sol)


    println("Fin de l'action timing")
end
