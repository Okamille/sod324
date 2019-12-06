
function main_carlo(args)
    println("="^70)
    println("Début de l'action carlo")

    # Affiche l'ensemble des options du programme (cf fichier args.jl)
    # Args.show_args()   # Déjà fait dans Args.jl

    inst = Instance(args[:infile])

    # Si :itermax vaut 0 (i.e automatique) on choisit une valeur "pertinante"
    itermax_default = 500*inst.nb_planes
    itermax = args[:itermax] == 0 ? itermax_default : args[:itermax]

    # Le timingSolver sous-jacent est choisi en fonction de l'option 
    # --timing-algo-solver (alias -t )
    # (Accessible par : Args.get(:timing_algo_solver))
    cursol = Solution(inst, update=true)
    bestsol = Solution(cursol)

    @show cursol
    @show bestsol
    @show itermax
    @show Args.get(:level)

    for i in 1:itermax
        # On contruit un ordre "intelligent"
        shuffle!(cursol, do_update=false)
        
        # Puis on lance l'algo de timing (presélectionné selon l'option --algo)
        # en fonction de l'ordre des avions ainsi contruit.
        solve!(cursol) 

        lg(i," ")
        if  cursol.cost < bestsol.cost
            # On mémorise ce record
            copy!(bestsol, cursol) 
            write(bestsol) 
            # On enregistre cette nouvelle solution dans un fichier

            if lg1()
                # Ce code n'est exécuter que si --level vaut au moins 1
                print(i, ":" , bestsol.cost)
                if lg2()
                    # Ce code n'est exécuter que si --level vaut au moins 2
                    print(to_s(bestsol))
                end
                println()
            end
        end
    end

    # le print_sol final n'est exécuté que si lg1() retourne true
    lg1() && print_sol(bestsol) 

    println("Fin de l'action carlo")
end

main_carlo(Args.args)
