
mutable struct MipDiscretSolver
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
    function MipDiscretSolver(inst::Instance)
        this=new()
        this.inst = inst
        this.loglevel = Args.get("level")
        this.bestsol = Solution(inst)
        this.mip_model = new_model(mode=:mip, log_level=this.loglevel)
        return this
    end
end


# Création du modèle discrétisé (plus lent, mais polyvalent)
#
function buildSeqataModel(sv::MipDiscretSolver)

    # nb d'avion, pour abréger l'écriture
    planes = sv.inst.planes
    n = sv.inst.nb_planes
    model = sv.mip_model

    # Quelques raccourcis car utilisés un peu partout
    lbmin = lb_min(sv.inst)
    ubmax = ub_max(sv.inst)

    #
    # Création des contraintes
    #

    # y: indicateur des dates d'atterrissage
    # y=1 si l'avion i atterrit à la date t dans [0,T-1]
    # @variable(model, y[p in planes, 1:ubmax], Bin) ORI pour indice Int et Plane
    @variable(model, y[p in planes, lbmin:ubmax], Bin)

    # variable dérivée : date d'atterrissage effective de l'avion i
    @expression(model, x[p in planes], sum(t*y[p,t] for t in lbmin:ubmax))
    sv.mip_x = x


    # Coût de chaque avion compte tenu de sa date d'atterrissage
    @expression(model, costs[p in planes],
            sum(get_cost(p,t)*y[p,t] for t in p.lb:p.ub))

    # Objectif Minimiser le coût de pénalité total
    @expression(model, total_cost,
                sum(get_cost(p,t)*y[p,t] for p in planes for t in lbmin:ubmax))

    sv.mip_costs = costs
    sv.mip_cost = total_cost

    @objective(model, Min, total_cost)

    #
    # Création des contraintes
    #

    # Contrainte sur les bornes de la date d'atterrissage
    # AMPL: C1 {i in 1..n} : E[i] <= x[i] <= L[i];
    @constraint(model, c1[p in planes], p.lb <= x[p] <= p.ub)

    # Chaque avion ne peut avoir qu'une seule date d'atterrissage.
    # AMPL: C2 {i in 1..n} : sum{t in T_SET} y[i,t] = 1;
    @constraint(model, c2[p in planes], sum(y[p,t] for t in lbmin:ubmax) == 1)

    # Deux dates d'atterrissage ne doivent pas être trop rapprochées
    # Principe :
    # - on prend toutes les paires d'avions possibles
    # - pour toutes les dates d'atterissage possibles de p1
    #   - on interdit a p2 d'atterrir dans la fenêtre trop près avant
    #     
    for p1 in planes, p2 in planes
        if !(p1.id<p2.id) continue end # évite de traiter le cas symétrique
        # ici p1 peut être avant ou après p2
        for t_i in p1.lb:p1.ub
            t_lb_j = max(p2.lb, t_i - get_sep(sv.inst, p2, p1) + 1) # p2 avant p1
            t_ub_j = min(p2.ub, t_i + get_sep(sv.inst, p1, p2) - 1) # p2 après p1
            for t_j in t_lb_j:t_ub_j
                # Si besoin de nommé les contraintes : c3[p1.id,p2.id,t_i,t_j]
                @constraint(model, y[p1,t_i] + y[p2,t_j] <= 1)
            end
        end
    end
end

# Résoud le problème complet : calcul l'ordre, le timing (dates d'atterrissage)
# et le cout total de la solution optimale au problème SEQATA (coûts linéaires)
# Cette fonction crée le modèle PLNE, le résoud puis met l'objet solution à
# jour.
#
function solve(sv::MipDiscretSolver)
    ln2("BEGIN solve(MipDiscretSolver)")
    ln2( "="^60 )

    lg2("Construction du modèle ($(ms())) ... ")
    buildSeqataModel(sv)
    ln2("fait ($(ms())).")

    lg2("Lancement de la résolution ($(ms())) ... ")
    optimize!(sv.mip_model)
    ln2("fait ($(ms())).")

    lg2("Exploitation des résultats ($(ms())) ... ")
    if  JuMP.termination_status(sv.mip_model) != MOI.OPTIMAL
        print("ERREUR : pas de solution pour :\n    ")
        @show JuMP.termination_status(sv.mip_model)
        println( to_s(sv.bestsol) )
        exit(1)
    end

    # Si les variables sv.mip_x et sv.mip_costs sont indicées par le planes (objet)
    #
    # Extraction des valeurs entières des variables d'atterrissage

    xvals = round.(Int, value.(sv.mip_x))

    # Il reste maintenant à mettre à jour notre objet solution à partir du
    # résultat de la résolution MIP
    #
    mip_costs = value.(sv.mip_costs)
    mip_cost = value(sv.mip_cost)

    for (i, p) in enumerate(sv.inst.planes)
        # p = sv.bestsol.planes[i]
        sv.bestsol.planes[i] = p
        sv.bestsol.x[i] = value(sv.mip_x[p])
        sv.bestsol.costs[i] = value(sv.mip_costs[p])
    end    
    sv.bestsol.cost = value(sv.mip_cost)


    # On trie juste la solution par date d'atterrissage croissante des avions
    # pour améliorer la présentation de la solution
    sort!(sv.bestsol)
    ln2("fait. ($(ms()))")

    ln2("END solve(MipDiscretSolver)")
end
