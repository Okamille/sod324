# Ce solveur résoud le  sous-problème de timing consistant à trouver les dates
# optimales d'atterrissage des avions à ordre fixé.
# Par rapport aux autres solvers, il ne contient pas d'attribut bestsol
#
mutable struct LpTimingSolver
    inst::Instance

    nb_calls::Int   # POUR FAIRE VOS MESURES DE PERFORMANCE !
    nb_infeasable::Int

    # A COMPLETER

    # Le constructeur
    function LpTimingSolver(inst::Instance)
        this=new()

        # A COMPLETER

        return this
    end
end
# Permettre de retrouver le nom de notre XxxxTimingSolver à partir de l'objet 
function symbol(sv::LpTimingSolver)
    return :lp
end

function solve!(sv::LpTimingSolver, sol::Solution)

    sv.nb_calls += 1
    # sv.mip_model = new_model()

    error("\n\nMéthode solve(sv::LpTimingSolver, ...) non implanté : AU BOULOT :-)\n\n")

    # ...
    # A COMPLETER
    # ...

    # 2. Création du modèle spécifiquement pour cet ordre d'avion
    #

    
    # 2. résolution du problème à permu d'avions fixée
    #
    # JuMP.optimize!(model)

    # # 3. Test de la validité du résultat
    # if  JuMP.termination_status(model) == MOI.OPTIMAL
    #     # tout va bien, on peut exploiter le résultat

    #     # 4. Extraction des valeurs des variables d'atterrissage
    #     xvals = round.(Int, value.(sv.mip_x))
    #     mip_costs = value.(sv.mip_costs)
    #     cost = round(value(sv.mip_cost), digits=Args.args[:cost_precision])
    #     update_from!(sol, xvals, mip_costs, cost)
    # else
    #     # La solution du solver est invalide : on utilise le placement au plus
    #     # tôt de façon à disposer malgré tout d'un coût pénalisé afin de pouvoir
    #     # continuer la recherche heuristique de solutions.
    #     sv.nb_infeasable += 1
    #     solve_to_earliest!(sol)
    # end

    # println("END solve(LpTimingSolver, sol)")
end

