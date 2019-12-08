#!/bin/sh
#= La ligne shell suivante est en commentaire multiligne pour julia
exec julia --color=yes --startup-file=no --depwarn=no -- "$0" "$@"
=#

# AUTRE EXEMPLE DE RÉPERTOIRE DE TEST (cf QML.jl)
#   https://github.com/barche/QML.jl/blob/master/test/runtests.jl
#

global const APPDIR = dirname(dirname(realpath(@__FILE__())))
@show APPDIR

# Démarrage des fonctions de chronométrage
include("../src/time_util.jl")
println("Début des tests en ", ms(), "s")

using Test   
using Random 
using Printf 
using Dates  

if !@isdefined(Args)
    include("../src/args.jl")
end

if !@isdefined(APPDIR)
    include("../src/args.jl")
end


include("../src/log_util.jl")
include("../src/plane.jl")
include("../src/instance.jl")
include("../src/array_util.jl")
include("../src/solution.jl")

include("../src/solvers/earliest_timing.jl")

include("../src/instance_read_alp.jl")
include("../src/instance_generators.jl")
# include("../src/solution.jl")

include("seqata_test_util.jl")

Args.parse_commandline(["test"])

include("../src/usings.jl") # pour les solveurs PL

println("## TEST $(basename(@__FILE__)) ")

@show(ARGS)


#
# Phase 1 : construction de la liste explicite du/des fichiers à tester
# - soit le/les fichier(s) passés en paramètre et aucun autre
# - soit tous les fichiers :
#   - commençant par test-*
#   - sans les fichiers de test de performance *-perf.jl (car lents !)
#   - et sans un liste de fichier explicitement à ignorer
# 
global files = Vector{String}()
if !isempty(ARGS)
    # files = copy(ARGS)
    for file in ARGS
        push!(files, basename(file))
    end
else
    # Calcul de la liste des tests par défaut
    # EXEMPLES DE FICHIERS À NE PAS INCLURE E.G. CAR LONGGG.
    # CES FICHIERS DOIVENT ÊTRE TESTÉS EXPLICITEMENT EN LES PASSANT EN PARAMETRE.
    excluded = [
        "test-14b-dmip-cbc.jl", # long (1.5mn)
        "test-14c-dmip-glpk.jl", # trés trés long !!
    ]
    # global old_pwd = pwd() # global sinon warning julia07
    old_pwd = pwd()
    cd(dirname(@__FILE__))
    allfiles = readdir()
    cd(old_pwd)

    for file in allfiles
        print("\nfile=$file ?...")

        # On exclue les fichiers ne commençant pas par test-
        !startswith(file, "test-") && continue

        # On exclue les fichiers explicitement indiqués
        # in(excluded, file) && continue # NE MARCHE PAS !!!!
        (file in excluded) && continue # ok

        # On exclue les fichiers dédié aux performancex (car très lentttts !)
        endswith(file, "-perf.jl") && continue

        print("  => OK")
        # @show file
        push!(files, file)
    end
end

println("Liste des $(length(files)) tests à effectuer :")
for file in files
    println("  $file")
end

#
# Phase 1 : exécution de chaque test dans un contexte indépendant
# - on se déplace éventuellement dans sont sous-répertoire
# - on capture une erreur éventuelle pour ne pas arreter les autres tests
# - on chronomètre chaque test
# 
@testset "Tests pour projet SEQATA" begin
    for file in files
        t0 = ms()
        println("\n"*"="^80)
        println("====== Test du fichier $(file)...")
        # global old_pwd = pwd() # global sinon warning julia07
        old_pwd = pwd()
        cd(dirname(@__FILE__))
        try
            @testset "Test $(file)" begin
                # println("include(", abspath(file), ")")
                include(abspath(file))
            end
        catch err
            println()
            # println(err)
            @warn err
            # rethrow(err)
        end
        cd(dirname(old_pwd))
        dt = round(ms()-t0, digits=3)
        println("====== Test du fichier $(file) fait en $(dt)s")
    end
    println("Fin des tests à ", ms(), "s")
end
# La suite ne serait pas exécutée en cas d'erreur
# println("Fin des tests en ", ms(), "s")

