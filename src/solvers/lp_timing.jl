# include("../instance.jl")
# include("../solution.jl")

# module LpTiming
# Déclaration des packages utilisés dans ce fichier
# certains sont déjà chargés dans le fichier usings.jl

# import JuMP
# using .Instance: Instance
# using .Solution: Solution, solve_to_earliest
# using .Model: new_model

# export LpTimingSolver

"""
Ce solveur résoud le  sous-problème de timing consistant à trouver les dates
optimales d'atterrissage des avions à ordre fixé.
Par rapport aux autres solvers (e.g DescentSolver, AnnealingSolver, ...), il
ne contient pas d'attribut bestsol 
"""
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

    # Le constructeur
    function LpTimingSolver(inst::Instance)
        model = new_model()
        return new(inst, 0, model, zeros(Int, inst.nb_planes),
                   0., zeros(Float64, inst.nb_planes), 0, 0)
    end
end

"""Permet de retrouver le nom de notre XxxxTimingSolver à partir de l'objet"""
function symbol(sv::LpTimingSolver)
    return :lp
end

"""
Trouve les temps d'atterrissage optimales pour un ordre d'avions donné par
la solution `sol`.

Les temps d'atterrissage de la solution sont modifiés in-place.

Cette fonction résoud un problème linéaire. Si le problème n'a pas de solution,
la stratégie d'atterrissage au plus tôt est appliquée.
"""
function solve!(sv::LpTimingSolver, sol::Solution)
    sv.nb_calls += 1
    model = new_model()

    n = sv.inst.nb_planes

    # 1. Création du modèle spécifiquement pour cet ordre d'avion de cette solution
    @variable(model, x[1:n] >= 0)
    @variable(model, y[1:n] >= 0)
    @variable(model, z[1:n] >= 0)

    @objective(model, Min,
               sum(plane.ep * y[i] + plane.tp * z[i]
                   for (i, plane) in enumerate(sol.planes)))

    for (i, plane) in enumerate(sol.planes)
        # Landing time bounds
        @constraint(model, x[i] >= plane.lb)
        @constraint(model, x[i] <= plane.ub)
        # Linearization
        @constraint(model, y[i] >= plane.target - x[i])
        @constraint(model, z[i] >= x[i] - plane.target)
        # Separation with planes landing later
        for (j, second_plane) in enumerate(sol.planes[i+1:end])
            @constraint(model, x[i+j] >= x[i] + get_sep(sv.inst, plane,
                                                        second_plane))
        end
    end

    # 2. résolution du problème à permu d'avion fixée
    JuMP.optimize!(model)

    # 3. Test de la validité du résultat
    if  JuMP.termination_status(model) == MOI.OPTIMAL
        # tout va bien, on peut exploiter le résultat

        # 4. Extraction des valeurs des variables d'atterrissage
        for (i, plane) in enumerate(sol.planes)
            sol.x[i] = round(Int, value(x[i]))
            sol.costs[i] = plane.ep * value(y[i]) + plane.tp * value(z[i])
        end
        prec = Args.args[:cost_precision]
        sol.cost = round(objective_value(model), digits=prec)
    else
        # La solution du solver est invalide : on utilise le placement au plus
        # tôt de façon à disposer malgré tout d'un coût pénalisé afin de pouvoir
        # continuer la recherche heuristique de solutions.
        sv.nb_infeasable += 1
        solve_to_earliest!(sol)
    end
end

# end
