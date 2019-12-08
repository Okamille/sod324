
# println("\nmain.jl: DEBUT DES INCLUDES à $(ms()).")
@ms include("args.jl");
@ms include("utils/log.jl")
@ms include("utils/console.jl")
@ms include("plane.jl")
@ms include("processing/instance.jl")
@ms include("processing/instance_read_alp.jl")
@ms include("utils/array.jl")
@ms include("utils/file.jl")
@ms include("processing/solution.jl")
@ms include("processing/solution_read.jl")

@ms using Dates

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

    if args[:action] == :validate
        include("$APPDIR/src/main_validate.jl")
    elseif args[:action] == :timing
        include("$APPDIR/src/main_timing.jl")
    elseif args[:action] == :carlo
        include("$APPDIR/src/main_carlo.jl")
    elseif args[:action] == :explore
        include("$APPDIR/src/main_explore.jl")
    elseif args[:action] == :descent
        include("$APPDIR/src/main_descent.jl")
    elseif args[:action] == :greedy
        include("$APPDIR/src/main_greedy.jl")
    elseif args[:action] == :annealing
        include("$APPDIR/src/main_annealing.jl")
    # elseif args[:action] == :mip
    #     include("$APPDIR/src/main_mip.jl")
    elseif args[:action] == :dmip
        include("$APPDIR/src/main_dmip.jl")
    elseif args[:action] == :stats
        include("$APPDIR/src/main_stats.jl")
    elseif args[:action] == :test
        include("$APPDIR/src/main_test.jl")
    elseif args[:action] == :none
        # include("$APPDIR/src/main_test.jl")
        println("Aucune action indiquée")
        # println("Actions possibles : ", join(actions(), ","))
        println(Args.get_syntaxe())
        # println(Args.get_actions())
        exit(1)
    else
        println("Erreur : action $(args[:action]) non implémentée (dans main.jl)")
        println(Args.get_syntaxe())
        exit(1)
    end

    # heure de fin du traitement
    time2= time()
    sec = round((time() - time1), digits=3) # on veut limiter la précision à la ms
    ln1("Durée totale du main 1000*(time2-time1) : $(sec)s")
    ln1("main() END")
end
