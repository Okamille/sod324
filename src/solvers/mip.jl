
mutable struct MipSolver
    inst::Instance
    loglevel::Int         # niveau de verbosité
    bestsol::Solution     # meilleure Solution rencontrée
    # Les attribut spécifiques au modèle
    mip_model::Model  # Le modèle MIP
    mip_x         # vecteur des variables d'atterrissage
    mip_b         # vecteur des variables de précédence (before)
    mip_cost      # variable du cout de la solution
    mip_costs     # variables du cout de chaque avion

    # Le constructeur
    function MipSolver(inst::Instance)
        ln1("MipSolver : constructeur avec $(Args.get("external_mip_solver"))")
        this=new()
        this.inst = inst
        this.loglevel = Args.get("level")
        this.bestsol = Solution(inst)
        # solver = Args.get("external_mip_solver") # NON UTILISÉ !
        # Création et configuration du modèle selon le solveur interne sélectionné
        this.mip_model = new_model(mode=:mip, log_level=this.loglevel)
        return this
    end
end

function buildSeqataModel(sv::MipSolver)
    # Quelques variables locales, pour abréger l'écriture
    planes = sv.inst.planes
    n = length(planes)
    model = sv.mip_model

    # Précalcul du coût de retard/avance pour chaque avion et chaque date
    # d'atterrissage.
    # La matrice des coûts est initialisée avec des coûts très élevés.
    # La vraie valeur de ces coûts sera calculée dans le domaine de validité de
    # la date d'atterrissage (dans l'intervale plane.lb:plane.ub)

    # Le big M (on a intérêt à l'optimiser !)
    # M = 4000
    #
    # Calcul de M minimum possible pour chaque couple de (i,j)
    # Si i est avant j, on veut (contrainte c2_sep) :
    #    xj >= xi + S_ij - M  =>  M >= xi - xj + S_ij
    # Donc on construit M[i,j] comme suit (+ 1 de sécurité)
    #    M := ub[i] - lb[j] + S_ij + 1
    M = Matrix{Int}(undef, sv.inst.nb_planes, sv.inst.nb_planes)
    for p1 in sv.inst.planes, p2 in sv.inst.planes
        M[p1.id,p2.id] = p1.ub - p2.lb + get_sep(sv.inst, p1, p2)
    end
    lg1() && @show maximum(M)


    # dates d'atterrissage effective
    @variable(model, x[1:n])
    # @variable(model, x[1:n], Int)
    sv.mip_x = x

    # coût retard/avance pour chaque avion
    @variable(model, costs[1:n])
    sv.mip_costs = costs

    # before : b[i,j] = 1 ssi i est avant j
    @variable(model, b[1:n,1:n], Bin)
    sv.mip_b = b

    # avec JuMP (contrairement à AMPL mais comme OPL) on peut définir des
    # expressions intermédiaires qui ne sont pas des variables de décision
    # (mais qui les utilisent).
    # Ces expressions pourront être exploitées dans le fonction objectif ou
    # pour faciliter l'affichage :
    @expression(model, total_cost, sum(costs))
    sv.mip_cost = total_cost

    #
    # Objectif Minimiser le retard total
    #
    @objective(model, Min, sv.mip_cost)

    #
    # Les contraintes
    #

    # Contrainte sur les bornes de la date d'atterrissage de chaque avion
    # c1_bounds = Array{VariableRef}(undef, n)
    # for i in 1:n
    #     p = planes[i]
    #     # # Création d'un contrainte anonyme (car le nom est inutile
    #     # # et création multiple => warning sous julia0.6)
    #     # # @constraint(model, c1_bounds[i], p.lb <= x[i] <= p.ub)
    #     # #
    #     # # Ces doubles bound mal sont encore mal supportées par les solveurs
    #     # # cplex, glpk et clp (même avec julia-0.6.1 et julia-0.7)
    #     # #     @constraint(model, p.lb <= x[i] <= p.ub)
    #     # @constraint(model, p.lb <= x[i]) # name: c1_bounds_lb[i]
    #     # @constraint(model, x[i] <= p.ub) # name: c1_bounds_ub[i]

    #     @constraint(model, c1_bounds[i], p.lb <= x[i] <= p.ub)
    # end
    @constraint(model, c1_bounds[p in planes], p.lb <= x[p.id] <= p.ub)


    for p1 in planes, p2 in planes
        if p1==p2 continue end
        # ATTENTION ,  POUR L'INSTANT ON DOIT FAIRE M*xxx et pas xxx*M
        # Mais ce sera possible à partir de la version de julia-0.4
        # @constraint(model, c2_sep[p1.id,p2.id],
        #     x[p2.id] >= x[p1.id] + get_sep(s.inst, p1, p2) - M*(1-b[p1.id, p2.id]))
        @constraint(model,
                    x[p2.id] >= x[p1.id] + get_sep(sv.inst, p1, p2)
                                - M[p1.id, p2.id]*(1-b[p1.id, p2.id]))

        # @constraint(model, c3_before_is_exclusive[p1.id, p2.id],
        #     b[p1.id, p2.id] + b[p2.id, p1.id] == 1)
        @constraint(model,
                    b[p1.id, p2.id] + b[p2.id, p1.id] == 1)
    end

    for p in planes
        # Principe: pour chaque segment de l'avion (paire successive de
        # timecosts), on ajoute la contrainte suivante :
        #    Le coût de l'avion est >= la droite associée au segment
        # L'équation de la droite du segment est de la forme :
        #  c = slope*(t-t1) + c1
        #  c = (c2-c1)/(t2-t1) * (t-t1) + c1
        if p.lb==p.ub
            # MAIS... certains avions dégénérés n'ont qu'un seul timecost avec
            # avec date d'atterrissage fiées : p.lb==p.target==p.ub
            # On les traite à part en imposant leur variable
            # date x[p.id] et leur costs[p.id]
            @constraint(model, costs[p.id] == 0.0)
            @constraint(model, x[p.id] == p.target)
        else
            for j = 1:(length(p.timecosts)-1)
                t1 = p.timecosts[j][1]
                c1 = p.timecosts[j][2]
                t2 = p.timecosts[j+1][1]
                c2 = p.timecosts[j+1][2]
                slope = (c2-c1)/(t2-t1)
                cst=@constraint(model, costs[p.id] >= c1 + slope*(x[p.id]-t1))
                # @show t1, c1, t2, c2, slope
                # @show cst
            end
        end
    end

end

# Résoud le problème complet : calcul l'ordre, le timing (dates d'atterrissage)
# et le cout total de la solution optimale au problème SEQATA (coûts linéaires)
# Cette fonction crée le modèle PLNE, le résoud puis met l'objet solution à
# jour.
#
function solve(sv::MipSolver)
    ln1("BEGIN solve(MipSolver)")

    ln1( "="^60 )
    ln1("Construction du modèle\n")
    buildSeqataModel(sv)

    ln1( "="^60 )
    ln1("Lancement de la résolution\n")

    # On prefixe la méthode solve par le nom du module pour éviter tout conflit avec
    # mes propres méthodes solve()
    # @show sv.mip_model
    if lg1()
        @ms optimize!(sv.mip_model)
    else
        optimize!(sv.mip_model)
    end

    ln1( "="^60 )
    ln1("Exploitation des résultats\n")
    if  JuMP.termination_status(sv.mip_model) != MOI.OPTIMAL
        print("ERREUR : pas de solution pour :\n    ")
        ln1("JuMP.termination_status(sv.mip_model)=", JuMP.termination_status(sv.mip_model))
        ln1( to_s(sv.bestsol) )
        exit(1)
    end

    # Extraction des valeurs entières des variables d'atterrissage
    xvals = round.(Int, value.(sv.mip_x))

    # Il reste maintenant à mettre à jour notre objet solution à partir du
    # résultat de la résolution MIP
    #
    mip_costs = value.(sv.mip_costs)
    mip_cost = round(value(sv.mip_cost), digits=Args.get(:cost_precision))

    # copy!(sv.bestsol, sv.inst.planes, xvals, mip_costs, mip_cost) # ORI
    update_from!(sv.bestsol, xvals, mip_costs, mip_cost)

    # On trie juste la solution par date d'atterrissage croissante des avions
    # pour améliorer la présentation de la solution
    sort!(sv.bestsol)

    ln1("END solve(MipSolver)")
end
# END TYPE DescentSolver
