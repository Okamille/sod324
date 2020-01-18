# BEGIN TYPE DescentSolver

# AMELIORATION POSSIBLE
# - revoir la gestion des options du solver (utiliser les params par clé-valeur)
# - plus besoin de gérer cursol (car ici, bestsol suffit contrainrement au
#   ExploreSolver)
"""Descent Solver

Args:
    inst (Instance)
    nb_test (Int): Nombre total de voisins testé
    nb_move (Int): nombre de voisins acceptés (améliorant ou non)
    nb_reject (Int): nombre de voisins refusés
    nb_cons_reject (Int): Nombre de refus consécutifs
    nb_cons_reject_max (Int): Nombre maxi de refus consécutifs

    duration (Float64): Durée réelle (mesurée) de l'exécution
    durationmax (Float64): Durée max de l'exécution (--duration)
    starttime (Float64): Heure de début d'une résolution

    cursol (Solution): Solution courante
    bestsol (Solution): Meilleure Solution rencontrée
    testsol (Solution): Nouvelle solution potentielle

    bestiter (Int)
    do_save_bestsol (Bool)

Notes:
    Amélioriations possibles:

        - revoir la gestion des options du solver (utiliser les params par clé-valeur)
        - plus besoin de gérer cursol (car ici, bestsol suffit contrainrement au ExploreSolver) 

"""
mutable struct DescentSolver
    inst::Instance
    nb_test::Int          # Nombre total de voisins testé
    nb_move::Int          # nombre de voisins acceptés (améliorant ou non)
    nb_reject::Int        # nombre de voisins refusés
    nb_cons_reject::Int   # Nombre de refus consécutifs
    nb_cons_reject_max::Int # Nombre maxi de refus consécutifs

    duration::Float64     # durée réelle (mesurée) de l'exécution
    durationmax::Float64  # durée max de l'exécution (--duration)
    starttime::Float64    # heure de début d'une résolution

    cursol::Solution      # Solution courante
    bestsol::Solution     # meilleure Solution rencontrée
    testsol::Solution     # nouvelle solution potentielle

    bestiter::Int
    do_save_bestsol::Bool
end

function DescentSolver(inst::Instance;
                       startsol::Union{Nothing,Solution} = nothing)
    nb_test = 0
    nb_move = 0
    nb_reject = 0
    nb_cons_reject = 0
    nb_cons_reject_max = 10_000_000_000 # infini

    bestiter = 0

    durationmax = 366*24*3600 # 1 année par défaut !
    duration = 0.0 # juste pour initialisation
    starttime = 0.0 # juste pour initialisation

    if startsol === nothing
        # Pas de solution initiale => on en crée une
        cursol = Solution(inst)
    else
        cursol = startsol
        if lg2()
            println("Dans DescentSolver : cursol = opts[:startsol] ")
            println("cursol", to_s(cursol))
        end
    end

    bestsol = Solution(cursol)
    testsol = Solution(cursol)
    do_save_bestsol = true
    descent_solver = DescentSolver(inst, nb_test, nb_move, nb_reject,
                                    nb_cons_reject, nb_cons_reject_max, duration,
                                    durationmax, starttime, cursol, bestsol,
                                    testsol, bestiter, do_save_bestsol)
    return descent_solver
end

"""Retourne true ssi l'état justifie l'arrêt de l'algorithme"""
function finished(sv::DescentSolver)
    sv.duration = time_ns()/1_000_000_000 - sv.starttime
    too_long = sv.duration >= sv.durationmax
    too_many_reject = (sv.nb_cons_reject >= sv.nb_cons_reject_max)
    stop = too_long || too_many_reject
    if stop
        if lg1()
            println("\nSTOP car :")
            println("     sv.nb_cons_reject=$(sv.nb_cons_reject)")
            println("     sv.nb_cons_reject_max=$(sv.nb_cons_reject_max)")
            println("     sv.duration=$(sv.duration)")
            println("     sv.durationmax=$(sv.durationmax)")
            println(get_stats(sv))
        end
        return true
    else
        return false
    end
end

function solve(sv::DescentSolver;
               nb_cons_reject_max::Int = 0,
               startsol::Union{Nothing,Solution} = nothing,
               durationmax::Int = 0
               )
    ln2("BEGIN solve(DescentSolver)")
    if durationmax != 0
        sv.durationmax = durationmax
    end

    if startsol != nothing
        sv.cursol = startsol
        if sv.cursol.cost < sv.bestsol.cost
            copy!(sv.bestsol, sv.cursol) # cursol peut avoir été meilleure !
        end
        copy!(sv.testsol, sv.cursol)
        if lg2()
            println("Dans DescentSolver : sv.cursol = sv.opts[:startsol] ")
            println("sv.cursol", to_s(sv.cursol))
        end
    else
        # on garde la dernière solution sv.cursol
    end

    sv.starttime = time_ns()/1_000_000_000
    if nb_cons_reject_max != 0
        sv.nb_cons_reject_max = nb_cons_reject_max
    end

    if lg3()
        println("Début de solve : get_stats(sv)=\n", get_stats(sv))
    end

    while !finished(sv)
        sv.nb_test += 1

        copy!(sv.testsol, sv.cursol)
        swap!(sv.testsol)
        sv.nb_test += 1

        degrad = sv.testsol.cost - sv.cursol.cost

        ln4("degrad=$(degrad)")
        if degrad < 0
            println("degrad=$(degrad)")
            sv.nb_cons_reject = 0
            sv.nb_move += 1
            copy!(sv.cursol, sv.testsol)
            if sv.cursol.cost < sv.bestsol.cost
                copy!(sv.bestsol, sv.cursol)
                if lg1()
                    msg = string("\niter ", sv.nb_test, "=", sv.nb_reject, "+",
                                 sv.nb_move)
                    if lg2()
                        # affiche coût + ordre des avions
                        msg *= string(" => ", to_s(sv.bestsol))
                    else
                        # affiche seulement le coût
                        msg *= string(" => ", sv.bestsol.cost)
                    end
                    print(msg)
                end
            end
        else
            sv.nb_reject += 1
            sv.nb_cons_reject += 1
        end

        # On peut ici tirer aléatoirement des voisinages différents plus ou 
        # moins large (exemple un swap simple ou deux swaps proches, ...)
        # # flottant entre 0 et 1
        # proba = rand()
        # # entier dans [1, n] :
        # i1 = rand(1:sv.inst.nb_planes)
        # 
        # On modifie testsol, puis on teste sa valeur, puis on...

        # ...

    end # fin while !finished
    ln2("END solve(DescentSolver)")
end

"""
    sample_two_shifts(sol::Solution; ecartmaxin::Int=10, ecartmaxout::Int=-1)

Retourne un quadruplet d'indices destiné à affectuer deux shifts relativement
proches
- ecartmaxin est l'écart maxi au sein d'une paire d'indices
- ecartmaxout est l'écart maxi entre deux paires d'indices (cumulables)
- ecartmaxin et ecartmaxout sont imposés dans les bornes de l'instance
- abs(i2-i1) et abs(i4-i3) sont limités par ecartmaxin
- i3 est distant au maximum de ecartmaxout du couple (i1,i2)
"""
function sample_two_shifts(sol::Solution; ecartmaxin::Int=10, ecartmaxout::Int=-1)
    # Version stupide car trop large !
    i1, i2, i3, i4 = rand(1:sol.inst.nb_planes, 4)
    return (i1, i2, i3, i4)
end

function record_bestsol(sv::DescentSolver; movemsg="")
    copy!(sv.bestsol, sv.cursol)
    sv.bestiter = sv.nb_test
    if sv.do_save_bestsol
        write(sv.bestsol)
    end
    if lg3()
        print("\niter $(rpad(sv.nb_test, 4)):$(sv.nb_move)+$(sv.nb_reject) ")
        print("$movemsg ")
        print("bestsol=$(to_s(sv.bestsol))")
    elseif lg1()
        print("\niter $(rpad(sv.nb_test, 4)):$(sv.nb_move)+$(sv.nb_reject) ")
        print("$movemsg => bestcost=", sv.cursol.cost)
    end
end

function get_stats(sv::DescentSolver)
    # txt = <<-EOT.gsub /^ {4}/,''
    txt = """
    ==Etat de l'objet DescentSolver==
    sv.nb_test=$(sv.nb_test)
    sv.nb_move=$(sv.nb_move)
    sv.nb_cons_reject=$(sv.nb_cons_reject)
    sv.nb_cons_reject_max=$(sv.nb_cons_reject_max)

    sv.duration=$(sv.duration)
    sv.durationmax=$(sv.durationmax)

    sv.testsol.cost=$(sv.testsol.cost)
    sv.cursol.cost=$(sv.cursol.cost)
    sv.bestsol.cost=$(sv.bestsol.cost)
    sv.bestiter=$(sv.bestiter)
    sv.testsol.solver.nb_infeasable=$(sv.testsol.solver.nb_infeasable)
    """
    txt = replace(txt, r"^ {4}" => "")
end

# END TYPE DescentSolver
