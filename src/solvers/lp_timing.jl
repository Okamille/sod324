
# Déclaration des packages utilisés dans ce fichier
# certains sont déjà chargés dans le fichier usings.jl


# Ce solveur résoud le  sous-problème de timing consistant à trouver les dates
# optimales d'atterrissage des avions à ordre fixé.
# Par rapport aux autres solvers (e.g DescentSolver, AnnealingSolver, ...), il
# ne contient pas d'attribut bestsol 
#
mutable struct LpTimingSolver
    inst::Instance
    loglevel::Int         # niveau de verbosité
    # Les attributs spécifiques au modèle
    model::Model  # Le modèle MIP
    x         # vecteur des variables d'atterrissage
    cost      # variable du coût de la solution
    costs     # variables du coût de chaque avion

    nb_calls::Int  # POUR FAIRE VOS MESURES DE PERFORMANCE !
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

    error("\n\nMéthode solve(sv::LpTimingSolver, ...) non implanté : AU BOULOT :-)\n\n")

    sv.nb_calls += 1
    sv.model = new_model()

    # ...
    # A COMPLETER
    # ...

    #
    # 1. Création du modèle spécifiquement pour cet ordre d'avion de cette solution
    #

    # 2. résolution du problème à permu d'avion fixée
    #
    # status=JuMP.solve(model, suppress_warnings=true)
    JuMP.optimize!(model)

    # # 3. Test de la validité du résultat
    # if  JuMP.termination_status(model) == MOI.OPTIMAL
    #     # tout va bien, on peut exploiter le résultat
    #
    #     # 4. Extraction des valeurs des variables d'atterrissage
    #     #
    #     # ATTENTION : les tableaux x et costs sont dans l'ordre de 
    #     # l'instance et non pas de la solution !
    #     for (i, p) in enumerate(sol.planes)
    #         sol.x[i] = round(Int,value(sv.x[p.id]))
    #         sol.costs[i] = value(sv.costs[p.id])
    #     end    
    #     prec = Args.args[:cost_precision]
    #     sol.cost = round(value(sv.cost), digits=prec)
    # else
    #     # La solution du solver est invalide : on utilise le placement au plus
    #     # tôt de façon à disposer malgré tout d'un coût pénalisé afin de pouvoir
    #     # continuer la recherche heuristique de solutions.
    #     sv.nb_infeasable += 1
    #     solve_to_earliest!(sol)
    # end

    # println("END solve(LpTimingSolver, sol)")
end
