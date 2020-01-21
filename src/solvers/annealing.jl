

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
    iter_in_step (Int): Nombre d'itérations effectués dans le palier courant

    nb_cons_reject (Int): Nombre de refus consécutifs
    nb_cons_reject_max (Int): Nombre maxi de refus consécutifs

    nb_cons_no_improv (Int): Nombre de tests non améliorants
    nb_cons_no_improv_max (Int): Nombre de maxi tests non améliorants

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
    iter_in_step::Int

    nb_cons_reject::Int
    nb_cons_reject_max::Float64

    nb_cons_no_improv::Int
    nb_cons_no_improv_max::Int

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
        temp_init = guess_temp_init(cursol, temp_init_rate, 100)
    end

    # A POURSUIVRE !! TODO

    bestsol = Solution(cursol)
    testsol = Solution(cursol)

    solver = AnnealingSolver(inst,
                             temp_init, temp_mini, temp_coef, temp_init,
                             0, 0, 0, 0, 0, step_size,
                             0, n_cons_reject_max,
                             0, nb_cons_no_improv_max,
                             cursol, bestsol, testsol)
    return solver
end

function solve(sv::AnnealingSolver, neighbour_operator!)
    println("BEGIN solve(AnnealingSolver)")

    current_costs = Vector{Float64}(undef, 10_000_000)
    while ! finished(sv)
    #    for _ in 1:sv.nb_steps
            copy!(sv.testsol, sv.cursol)
            neighbour_operator!(sv.testsol)
            # println(exp(-(sv.testsol.cost - sv.cursol.cost) / sv.temp))
            # println(sv.testsol.cost)
            # println(sv.cursol.cost)
            # println()
            # println("Ratio : ", sv.nb_move / sv.nb_steps)
            # println("Temperature : ", sv.temp)
            # println("Degradation : ", sv.testsol.cost - sv.cursol.cost)
            # println("Acceptation proba : ", exp(-(max(sv.testsol.cost - sv.cursol.cost, 0)) / sv.temp))
            sv.nb_steps += 1
            if rand() < exp(-(max(sv.testsol.cost - sv.cursol.cost, 0)) / sv.temp)
                copy!(sv.cursol, sv.testsol)
                sv.nb_cons_reject = 0
                sv.nb_move += 1
                # println(sv.testsol.cost)
            else
                sv.nb_cons_reject += 1
                sv.nb_reject += 1
                sv.nb_cons_no_improv += 1
            end
            if sv.testsol.cost < sv.bestsol.cost
                println("Accepted solution with improvement : ", sv.bestsol.cost - sv.testsol.cost)
                copy!(sv.bestsol, sv.testsol)
            end
            current_costs[sv.nb_steps] = sv.cursol.cost
        # end
        sv.temp = max(sv.temp_coef * sv.temp, sv.temp_mini)
    end

    lg2() && println(get_stats(sv))
    println("END solve(AnnealingSolver)")
    return current_costs[1:sv.nb_steps]
end

function swap_operator!(sol::Solution)
    swap!(sol)
end

"""
Retourne true ssi l'état justifie l'arrêt de l'algorithme.

On pourra utiliser d'autres critères sans toucher au programme principal
"""
function finished(sv::AnnealingSolver)
    # return sv.nb_cons_reject >= sv.nb_cons_reject_max
    ratio = sv.nb_move / sv.nb_steps
    return ratio < sv.nb_cons_reject_max
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
function guess_temp_init(sol::Solution, taux_cible=0.8, nb_degrad_max=1000)
    # we apply the formula : exp(-delta_h/T_0) = taux_cible
    # from the formula we get -delta_h / ln(taux_cible) = T_0
    #t_init = 0    # stupide : pour faire une descente pure !
    # Initialisations diverses
    
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
