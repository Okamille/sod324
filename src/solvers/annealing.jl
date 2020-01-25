include("./logging.jl")

"""Annealing solver

Attributes:
    inst (Instance): instance

    temp_init (Float64): température courante
    temp_mini (Float64): température mini avant arrêt
    temp_coef (Float64): coefficiant de refroidissement
    temp (Float64): température courante

    nb_test (Int): Nombre total de voisins testés
    nb_move (Int): Nombre de voisins acceptés (améliorant ou non)
    nb_reject (Int): Nombre de voisins refusés
    nb_steps (Int): Nombre de paliers à température constante effectués
    step_size (Int): Nombre d'itérations à température constante

    nb_cons_reject (Int): Nombre de refus consécutifs
    nb_cons_reject_max (Int): Nombre maxi de refus consécutifs

    nb_cons_no_improv (Int): Nombre de tests non améliorants
    nb_cons_no_improv_max (Int): Nombre de maxi tests non améliorants

    duration (Float64): Durée réelle (mesurée) de l'exécution
    durationmax (Float64): Durée max de l'exécution (--duration)
    starttime (Float64): Heure de début d'une résolution

    cursol (Solution): Solution courante
    bestsol (Solution): meilleure Solution rencontrée
    testsol (Solution): nouvelle solution courante potentielle
"""
mutable struct AnnealingSolver
    inst::Instance

    temp_init::Float64
    temp_mini::Float64
    temp_coef::Float64
    temp::Float64

    nb_test::Int
    nb_move::Int
    nb_reject::Int
    nb_steps::Int
    step_size::Int

    nb_cons_reject::Int
    nb_cons_reject_max::Float64

    nb_cons_no_improv::Int
    nb_cons_no_improv_max::Int

    duration::Float64
    durationmax::Float64
    starttime::Float64

    cursol::Solution
    bestsol::Solution
    testsol::Solution
end

"""Annealing solver outer constructor"""
function AnnealingSolver(inst::Instance; 
                         temp_init=nothing, temp_init_rate=0.75, temp_mini=1e-6,
                         temp_coef=0.999_999_9, step_size=1,
                         n_cons_reject_max=0.001,
                         nb_cons_no_improv_max=nothing,
                         startsol=nothing)

    if nb_cons_no_improv_max === nothing
        nb_cons_no_improv_max = 5000 * inst.nb_planes
    end

    cursol = startsol === nothing ? Solution(inst) : startsol

    # On calcule éventuellement la température initiale automatiquement
    if temp_init === nothing
        temp_init = guess_temp_init_cost(cursol, temp_init_rate)
    end

    bestsol = Solution(cursol)
    testsol = Solution(cursol)

    durationmax = 15*60
    duration = 0.0
    starttime = 0.0

    solver = AnnealingSolver(inst,
                             temp_init, temp_mini, temp_coef, temp_init,
                             0, 0, 0, 0, 0, step_size,
                             n_cons_reject_max,
                             0, nb_cons_no_improv_max,
                             durationmax, duration, starttime,
                             cursol, bestsol, testsol)
    return solver
end

function solve(sv::AnnealingSolver, neighbour_operator!;
               durationmax::Int = 0)
    ln2("BEGIN solve(AnnealingSolver)")

    if durationmax != 0
        sv.durationmax = durationmax
    end

    sv.starttime = time_ns()/1_000_000_000
    while ! finished(sv)
        for iter_in_step in 1:sv.step_size
            copy!(sv.testsol, sv.cursol)
            neighbour_operator!(sv.testsol)
            sv.test += 1
            if sv.testsol.cost < sv.cursol.cost
                copy!(sv.cursol, sv.testsol)
                if sv.cursol.cost < sv.bestsol.cost
                    print_log(sv)
                    copy!(sv.bestsol, sv.cursol)
                end
                sv.nb_cons_reject = 0
                sv.nb_move += 1
            elseif rand() < exp(-(sv.testsol.cost - sv.cursol.cost) / sv.temp)
                copy!(sv.cursol, sv.testsol)
                sv.nb_cons_reject = 0
                sv.nb_move += 1
            else
                sv.nb_cons_reject += 1
                sv.nb_reject += 1
                sv.nb_cons_no_improv += 1
            end
        end
        sv.nb_steps += 1
        sv.temp = max(sv.temp_coef * sv.temp, sv.temp_mini)
    end
    lg2() && println(get_stats(sv))
    ln2("END solve(AnnealingSolver)")
end

"""
Retourne true ssi l'état justifie l'arrêt de l'algorithme.

On pourra utiliser d'autres critères sans toucher au programme principal
"""
function finished(sv::AnnealingSolver)
    # return sv.nb_cons_reject >= sv.nb_cons_reject_max
    sv.duration = time_ns()/1_000_000_000 - sv.starttime
    too_long = sv.duration >= sv.durationmax
    ratio = sv.nb_move / sv.nb_test
    too_many_cons_reject = ratio < sv.nb_cons_reject_max 
    return too_many_cons_reject || too_long
end


"""
Calcul d'une température initiale de manière à avoir un taux d'acceptation τ en démarrage

Args:
    taux_cible: pourcentage représentant le taux d'acceptation cible(e.g. 0.8)
    nb_degrad_max: nbre de degradation à accepter pour le calcul de la moyenne

On lance une suite de mutations (succession de mouvement systématiquement
acceptés). On relève le nombre et la moyenne des mouvements conduisant à une
dégradation du coût de la solution.

degrad : dégradation moyenne du coût pour deux mutations consécutives de coût croissant

La probabilité standard d'acceptation d'une mauvaise solution est :

..math::
    p = e^{ -degrad/T } = 0.8    =>    T = t_init = -degrad / ln(p)

avec :

- p = taux_cible = proba(t_init)
- degrad = moyenne des dégradations de l'énergie
- T = t_init = la température initiale à calculer

Example:
    On va lancer des mutations jusqu'à avoir 1000 dégradations.
    Si par exemple le coût des voisins forme une suite de la forme :
    990, 1010, 990, 1010, 990,...
    On devra faire 2000 mutations pour obtenir 1000 dégradations de valeur 20,
    d'où t_init = -degrad / ln(proba)
    proba = 0.8   =>  t_init = degrad * 4.5
    proba = 0.37  =>  t_init = degrad

Attention:
    Cette fonction n'est **pas** une méthode de AnnealingSolver.
    Elle a juste besoin d'une solution et du type de mouvement à effectuer.
    Ici, on suppose que le seul mouvement possible est swap!(sol::Solution)
    Mais il faudra pouvoir paramétrer cette méthode pour des voisinages différents.

"""
function guess_temp_init_degrad(sol::Solution, nb_degrad_max::Int;
                                taux_cible=0.8)
    # we apply the formula : exp(-delta_h/T_0) = taux_cible
    # from the formula we get -delta_h / ln(taux_cible) = T_0
    #t_init = 0    # stupide : pour faire une descente pure !    
    nb_degrad = 0
    last_cost = sol.cost
    degrads = []
    cursol = Solution(sol)
    while nb_degrad < nb_degrad_max
        # We go back from initial solution
        swap!(cursol)
        degrad = last_cost - cursol.cost
        last_cost = cursol.cost
        if degrad > 0
            nb_degrad += 1
            push!(degrads, degrad)
        end
    end

    delta = mean(degrads)

    t_init = - delta / log(taux_cible)
    ln2("Temp init : ", t_init)
    return t_init
end

"""
Suppose que les variations de coût sont de l'ordre du coût trouvé par
le glouton.
"""
function guess_temp_init_cost(sol::Solution, taux_cible=0.8)
    delta = sol.cost
    t_init = - delta / log(taux_cible)
    ln2("Temp init : ", t_init)
    return t_init
end

function get_stats(sv::AnnealingSolver)
    # temp_init_rate=    $(sv.temp_init_rate)
    txt = "
    Paramètres de l'objet AnnealingSolver :
    step_size=         $(sv.step_size)
    temp_init=         $(sv.temp_init)
    temp_mini=         $(sv.temp_mini)
    temp_coef=         $(sv.temp_coef)
    nb_cons_reject_max=$(sv.nb_cons_reject_max)
    Etat de l'objet AnnealingSolver :
    nb_steps=$(sv.nb_steps) step_size=$(sv.step_size)
    nb_cons_reject=$(sv.nb_cons_reject) nb_cons_reject_max=$(sv.nb_cons_reject_max)
    nb_cons_no_improv=$(sv.nb_cons_no_improv) nb_cons_no_improv_max=$(sv.nb_cons_no_improv_max)
    nb_test=$(sv.nb_test)
    nb_move=$(sv.nb_move)
    nb_reject=$(sv.nb_reject)
    temp=$(sv.temp) temp_init=$(sv.temp_init)
    testsol.cost=$(sv.testsol.cost)
    cursol.cost=$(sv.cursol.cost)
    bestsol.cost=$(sv.bestsol.cost)
    sv.testsol.solver.nb_infeasable=$(sv.testsol.solver.nb_infeasable)
    "
    # temp_init_rate=    $(sv.temp_init_rate)"
    return replace(txt, r"^ {4}" => "")
end
