#!/bin/sh
#= La ligne shell suivante est en commentaire multiligne pour julia
exec julia --color=yes --startup-file=no --depwarn=no -- "$0" "$@"
=#

# IDÉE TODO :
# - faire macros @p (pour print intelligent) et @s (pour to_string générique)

# Le realpath est nécessaire si l'un des répertoire parents est un lien 
# symbolique :
global const APPDIR = dirname(dirname(realpath(@__FILE__())))
@show APPDIR
# utile pour les includes mais fonctionnement douteux !?
push!(LOAD_PATH, "$APPDIR/src")
println("LOAD_PATH=\n    ", join(LOAD_PATH, "\n    "))

include("$APPDIR/src/time_util.jl") # pour la macro @ms()

using Printf
using Random
using Dates


if basename(@__FILE__) == basename(PROGRAM_FILE)
    # Mode d'appel normal : on exécute le programme "bin/xxx.jl"
    @ms include("$APPDIR/src/main.jl")
    main()
else
    # Mode interactif de l'exécutable seqata.lj
    #
    # Exécution par :
    #    julia -iL ./bin/seqata.jl
    #    julia -i --color=yes -L  ./bin/seqata.jl
    #    include("test/test-21-mutation_move2x_solution.jl")
    #     
    # - le main n'est pas appelé
    # - on inclue tous les packages et les includes possibles
    # - l'analyse des arguments est faite
    # - on charge le fichier d'utilitatire dédié au mode interactif
    #

    # @ms using Revise # pour rechargement dynamique des fichiers/fonctions modifiés
    # MAIS NE FONCTIONNE QUE POUR DES FONCTIONS INTÉGRÉES DANS UN PACKAGE 
    # (donc ne fonctionne par avec seqata pour l'instant)
    # using Revise # pour rechargement dynamique des fichiers/fonctions modifiés

    @ms include("$APPDIR/src/args.jl");
    @ms include("$APPDIR/src/log_util.jl")
    @ms include("$APPDIR/src/console_util.jl")
    @ms include("$APPDIR/src/plane.jl")
    @ms include("$APPDIR/src/instance.jl")
    @ms include("$APPDIR/src/instance_generators.jl")
    @ms include("$APPDIR/src/instance_read_alp.jl")
    @ms include("$APPDIR/src/array_util.jl")
    @ms include("$APPDIR/src/file_util.jl")
    @ms include("$APPDIR/src/solution.jl")
    @ms include("$APPDIR/src/solution_readsol.jl")

    @ms using JuMP
    @ms using CPLEX
    @ms using Glob
    @ms using Dates
    @ms using Test


    @ms include("$APPDIR/src/model_util.jl")
    @ms include("$APPDIR/src/earliest_timing_solver.jl")
    @ms include("$APPDIR/src/lp_timing_solver.jl")
    @ms include("$APPDIR/src/mip_solver.jl")

    @ms include("$APPDIR/src/annealing_solver.jl")
    @ms include("$APPDIR/src/descent_solver.jl")
    @ms include("$APPDIR/src/explore_solver.jl")


    # On impose des arguments par défaut
    # ARGS = ["test"]
    # @ms args = Args.parse_commandline(["test"])
    @ms args = Args.parse_commandline()
    lg1() && Args.show_args()

    @ms include("../src/interactive.jl")

    println()
    println("Début de mode interactif de seqata.jl ($(ms()))s")
    println()

end
