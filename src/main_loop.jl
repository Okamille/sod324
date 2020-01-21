
# println("\nmain.jl: DEBUT DES INCLUDES à $(ms()).")
@ms include("args.jl");
@ms include("utils/log.jl")
@ms include("utils/console.jl")
@ms include("plane.jl")
@ms include("instance.jl")
@ms include("processing/instance_read_alp.jl")
@ms include("utils/array.jl")
@ms include("processing/file.jl")
@ms include("solution.jl")
@ms include("processing/solution_read.jl")

@ms using Dates

@ms include("utils/PlotUtils.jl")
@ms using .PlotUtils: plot_save_costs

# Les autres fichiers sont inclue seulement si nécessaire
# Dans les solveurs spécifiques ou dans le fichier usings.jl

# TODO :
# - faire les macros @p (pour imprimer) et @s (pour to_string générique)
#
# using DataStructures # risque de pollution du scope
# import DataStructures: OrderedDict

function main()
    @ms args = Args.parse_commandline(ARGS)
    ln1("main() BEGIN") # ln1 n'est utilisable que si level est connu
    lg1() && Args.show_args()

    # Le fichier suivant déclare différents solveurs PL/PLNE (par des instructions
    # `using ...`) selon les options de la ligne de commande.
    # Les instructions `using ...` **doivent** être dans des fichiers séparés et
    # non pas dans des fonctions
    #
    @time include("$APPDIR/src/usings.jl")

    # date1= now() # en secondes entières
    time1= time() # secondes précision microsecondes
    action = args[:action]
    if action == :validate
        include("$APPDIR/src/main_validate.jl")
        loop_validate(Args.args)
    # elseif action == :timing
    #     include("$APPDIR/src/main_timing.jl")
    #     loop_timing(Args.args)
    # elseif action == :carlo
    #     include("$APPDIR/src/main_carlo.jl")
    #     loop_carlo(Args.args)
    elseif action == :explore
        include("$APPDIR/src/main_explore.jl")
        loop_costs = main_explore(Args.args)
    # elseif action == :descent
    #     include("$APPDIR/src/main_descent.jl")
    #     loop_costs = main_descent(Args.args)
    # elseif action == :greedy
    #     include("$APPDIR/src/main_greedy.jl")
    #     loop_greedy(Args.args)
    # elseif action == :annealing
    #     include("$APPDIR/src/main_annealing.jl")
    #     loop_costs = main_annealing(Args.args)
    # elseif action == :mip
    #     include("$APPDIR/src/main_mip.jl")
    #     loop_mip(Args.args)
    # elseif action == :dmip
    #     include("$APPDIR/src/main_dmip.jl")
    #     loop_dmip(Args.args)
    elseif action == :none
        println("Aucune action indiquée")
        println(Args.get_syntaxe())
        exit(1)
    else
        println("Erreur : action $action non implémentée (dans main.jl)")
        println(Args.get_syntaxe())
        exit(1)
    end

    if costs !== nothing
        inst_name, _ = splitext(basename(args[:infile]))
        save_path = "$APPDIR/_tmp/figures/$(inst_name)_$(action)_$(args[:itermax])"
        plot_save_costs(costs, save_path, plot=args[:plot], save=args[:plot])
    end

    # heure de fin du traitement
    time2= time()
    sec = round((time() - time1), digits=3) # on veut limiter la précision à la ms
    ln1("Durée totale du main 1000*(time2-time1) : $(sec)s")
    ln1("main() END")
end
