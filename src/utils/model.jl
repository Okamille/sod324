# Quelques fonctions utilitaires pour les manipulations de solvers PL ou MIP

# Classe abstraite non utilisé
# abstract type AbstractLpSolver end

# Création d'un modèle de solver externe (:cplex, :glpk, ...)
# Options possibles :
#  solver : symbole :cplex, :glpk, :clp, :cbc
#     :cbc : permet de faire du MIP
#     :clp : resteint aux problème LP mais plus efficace de cbc pour les
#            relaxations.
#  mode : (:lp ou :mip) utile pour choisir entre :clp ou :cbc
#  log_level (expérimental) : entier 0 pour silence, sinon 1, 2, ...
#
# Autre solver à supporter plus tard Gurobi (concurrent de cplex)
#
# DEPENDANCE EXTERNE : module Args (pour Args.get("external_mip_solver"))
#
function new_model(;solver = :auto,
                     mode = :lp,
                     log_level = 0, # EXPLOITATION PARTIELLE
                     )
    if !(mode in [:mip, :lp])
        error("ERROR: unknown mode $(mode). Should be :cplex, :glpk, ...")
    end
    if solver == :auto
        solver = Args.get("external_mip_solver")
    end
    if solver in [:clp, :cbc]
        # solver = (mode == :mip ? :cbc : :clp )
        if mode==:mip
            solver = :cbc
        else
            solver = :clp
        end
    end
    if ! (solver in [:cplex, :clp, :cbc, :glpk])
        error("ERROR: unknown solver $(solver). Should be :cplex, :glpk, ...")
    end

    if solver == :glpk
        # voir https://github.com/JuliaOpt/GLPK.jl
        # model = Model(GLPK.Optimizer)  # PAS ENCORE SUPPORTE (05/12/2019)
        model = Model(with_optimizer(GLPK.Optimizer))
    elseif solver == :cplex
        model = Model(with_optimizer(CPLEX.Optimizer))
        # model = Model(CPLEX.Optimizer) # PAS ENCORE SUPPORTE (05/12/2019)
    elseif solver == :clp
        # voir https://github.com/JuliaOpt/Clp.jl
        # model = Model(Clp.Optimizer) # PAS ENCORE SUPPORTE (05/12/2019)
        model = Model(with_optimizer(Clp.Optimizer))
    elseif solver == :cbc
        # Voir https://github.com/JuliaOpt/Cbc.jl pour les options
        # model = Model(Cbc.Optimizer) # PAS ENCORE SUPPORTE (05/12/2019)
        model = Model(with_optimizer(Cbc.Optimizer))
    else
        error("LpTimingSolver: unknown external_mip_solver inconnu : $solver")
    end
    # MOI.set(model, MOI.Silent(), true) # Variante de bas niveau
    if log_level <= 3
        set_silent(model) # unset_silent(model) pour réautoriser affichage
    end
    return model
end
