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

# Permettre de retrouver le nom de notre XxxxTimingSolver à partir de l'objet 
function symbol(sv::LpTimingSolver)
    return :lp
end

function solve!(sv::LpTimingSolver, sol::Solution)
    sv.nb_calls += 1
    sv.model = new_model()

    n = sv.inst.nb_planes

    # 1. Création du modèle spécifiquement pour cet ordre d'avion de cette solution
    @variable(sv.model, x[1:n], Int)
    @variable(sv.model, z[1:n] >= 0)
    @variable(sv.model, y[1:n] >= 0)

    @objective(sv.model, Min, sum(plane.ep * y[i] + plane.tp * z[i]
                                  for (i, plane) in enumerate(sv.inst.planes)))

    @constraint(sv.model, y_linear_cons[i=1:n],
                y[i] >= sv.inst.planes[i].target - x[i])
    @constraint(sv.model, z_linear_cons[i=1:n],
                z[i] >= x[i] - sv.inst.planes[i].target)
    @constraint(sv.model, earliest_land[i=1:n],
                x[i] >= sv.inst.planes[i].lb)
    # @constraint(sv.model, latest_land[i=1:n], x[i] <= sv.inst.planes[i].hb)

    σ = sortperm(sol.x)

    @constraint(sv.model, separation[i=1:n-1],
                x[σ[i]] <= x[σ[i+1]] + sv.inst.sep_mat[σ[i], σ[i+1]])

    # 2. résolution du problème à permu d'avion fixée
    # status=JuMP.solve(model, suppress_warnings=true)
    JuMP.optimize!(sv.model)

    # 3. Test de la validité du résultat
    if  JuMP.termination_status(sv.model) == MOI.OPTIMAL
        # tout va bien, on peut exploiter le résultat
    
        # 4. Extraction des valeurs des variables d'atterrissage
        #
        # ATTENTION : les tableaux x et costs sont dans l'ordre de 
        # l'instance et non pas de la solution !
        for (i, p) in enumerate(sol.planes)
            sol.x[i] = round(Int,value(sv.x[p.id]))
            sol.costs[i] = value(sv.costs[p.id])
        end
        prec = Args.args[:cost_precision]
        sol.cost = round(value(sv.cost), digits=prec)
    else
        # La solution du solver est invalide : on utilise le placement au plus
        # tôt de façon à disposer malgré tout d'un coût pénalisé afin de pouvoir
        # continuer la recherche heuristique de solutions.
        sv.nb_infeasable += 1
        solve_to_earliest!(sol)
    end

    println("END solve(LpTimingSolver, sol)")
end

# end
