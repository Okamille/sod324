# Ce fichier doit être chargé **après** l'appel du main().
# On connait alors les options et on peut charger les solveurs
# utiles en fonction de ces options.
#
# Les choix de solveur (PLNE ou PL) sont :
# - avec les actions :mip ou :dmip : tout est fait en PLNE
#   Dans ce cas les solveurs possibles sont cplex, cbc ou glpk.
# - sinon la solution sous-traite le sous-problème de timing (positionner les
#   avions avec ordre imposé) à un solveur qui peut être :
#   - soit algorithmique pur (timing_algo_solver==:dynprog ou :earliest)
#   - soit par solveur PL (et pas PLNE). Dans ce cas les solveurs sont
#     cplex, glpk ou clp (clp à la place de cbc)

# On évite de sourcer ce même fichier plusieurs fois
if @isdefined(USINGS_IS_LOADED)
    return
end

# Cette ligne ne fonctionne que si l'analyse des arguments est déjà faite.
#
# choix possible  :cbc, :clp, :glpk, :cplex
external_mip_solver = Args.get("external_mip_solver")

# choix possible :  :earliest, :lp, :dynprog, ...
timing_algo_solver = Args.get("timing_algo_solver")

# action demandée : elle nécessite ou non le pkg JuMP
action = Args.get("action")

# Inclusion de JuMP et des solvers externes seulement si nécessaire
need_jump = false
# On peut avoir plusieurs classe LpTimingSolver (Lp2TimingSolver, ...)
use_timing_algo_solver = occursin(r"^lp", String(timing_algo_solver))
if (action in [:mip, :dmip] || use_timing_algo_solver )
    need_jump = true
end

# ulg pour usings::log (pour éviter de surcharger un lg par ailleurs)
# La première ligne évite les hurlements en cas de rechargement de ce fichier.
!@isdefined(ulg) && # la suite n'est effectuée qui le bool précédent est true.
function ulg(str)
    # if Args.get("level") >= 2
    if Args.get("level") >= 1
        println("usings.jl: $str")
    end
end

ulg("========================= USINGS BEGIN ($(ms()))")
ulg("action=$action")
ulg("need_jump=$need_jump")
ulg("external_mip_solver=$external_mip_solver")
ulg("timing_algo_solver=$timing_algo_solver")

if need_jump
    @ms using JuMP
    const MOI = JuMP.MathOptInterface
    # print("include solvers/lp_timing.jl $(ms())...")
    @ms include("model_util.jl")
    @ms include("solvers/lp_timing.jl")

    if external_mip_solver == :glpk
        # @ms using GLPKMathProgInterface
        @ms using GLPK
    elseif external_mip_solver == :cplex
        @ms using CPLEX
    elseif external_mip_solver in [:clp, :cbc]
        @ms using Cbc
        @ms using Clp
    else
        error("external_mip_solver inconnu : $external_mip_solver")
    end
end

if timing_algo_solver == :earliest
    @ms include("solvers/earliest_timing.jl")
end

USINGS_IS_LOADED = true
ulg("========================= USINGS END ($(ms()))")
