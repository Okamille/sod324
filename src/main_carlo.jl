
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
    cursol = Solution(inst, update=false)
    # Attention : bestsol ne doit pas recopier cursol car cursol ne sera pas la 
    # premiere solution explorée !
    bestsol = Solution(inst, update=false)

    @show cursol
    @show bestsol
    @show itermax
    @show Args.get(:level)

    ms_start = ms() # seconde depuis le démarrage avec précision à la ms
    for i in 1:itermax
        # On contruit un ordre "intelligent"

        # Cas particulier : si iterman==1 : on fait le meilleur coup possibe
        # en triant sur le target 
        if itermax == 1
            initial_sort!(cursol, presort=:target)
        else 
            shuffle!(cursol, do_update=false)
        end

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
    ms_stop = ms()

    # le print_sol final n'est exécuté que si lg1() retourne true
    lg1() && print_sol(bestsol) 

    nb_calls = bestsol.solver.nb_calls
    nb_infeasable = bestsol.solver.nb_infeasable
    nb_sec = round(ms_stop - ms_start, digits=3)
    nb_call_per_sec = round(nb_calls/nb_sec, digits=3)
    println("Performance: ")
    println("  nb_calls=$nb_calls")
    println("  nb_infeasable=$nb_infeasable")
    println("  nb_sec=$nb_sec")
    println("  => nb_call_per_sec = $nb_call_per_sec call/sec")

    println("Fin de l'action carlo")
end
