# Ce fichier n'est là que pour sélection et charer (par using) les packages
# strictement indispensable en fonction des options passées au programme.
# En effet les packages tels que JuMP, CPLE, Cbc, ... sont assez lents à charger
# et ne sont pas toujours indispensable selon les option.
# Par conséquent, ce fichier ne peut-être charger que après analyse des options.
#
# Les choix de solveur (PLNE ou PL) sont :
# - avec les actions :mip ou :dmip : tout est fait en PLNE
#   Dans ce cas les solveurs possibles sont cplex, cbc ou glpk.
# - sinon la solution sous-traite le sous-problème de timing (positionner les
#   avions avec ordre imposé) à un solveur qui peut être :
#   - soit algorithmique pur (timing_algo_solver==:dynprog ou :earliest)
#   - soit par solveur PL (et pas PLNE) (timing_algo_solver==:lp). 
#     Dans ce cas les solveurs sont cplex, glpk ou clp (clp à la place de cbc)

# On évite de sourcer ce même fichier plusieurs fois
if @isdefined(USINGS_IS_LOADED)
    return
end
ln1("========================= USINGS BEGIN ($(ms()))")

# Cette ligne ne fonctionne que si l'analyse des arguments est déjà faite.
#
# choix possible  :cbc, :clp, :glpk, :cplex
external_mip_solver = Args.get("external_mip_solver")

# choix possible :  :earliest, :lp, :dynprog, ...
timing_algo_solver = Args.get("timing_algo_solver")

# action demandée : elle nécessite ou non le pkg JuMP
action = Args.get("action")

# Nécessité de JuMP ?
need_jump = false
# On peut avoir plusieurs classe LpTimingSolver (Lp2TimingSolver, ...)
use_timing_algo_solver = occursin(r"^lp", String(timing_algo_solver))
# Cas d'un résolution globales par approche PLNE frontale.
if (action in [:mip, :dmip] || use_timing_algo_solver )
    need_jump = true
end

ln1("action=$action")
ln1("need_jump=$need_jump")
ln1("external_mip_solver=$external_mip_solver")
ln1("timing_algo_solver=$timing_algo_solver")

if need_jump
    @ms using JuMP
    const MOI = JuMP.MathOptInterface
    # print("include solvers/lp_timing.jl $(ms())...")
    @ms include("utils/model.jl")
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
ln1("========================= USINGS END ($(ms()))")
