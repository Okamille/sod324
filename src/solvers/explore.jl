# START TYPE ExploreSolver
mutable struct ExploreSolver
    inst::Instance
    nb_test::Int          # Nombre total de voisins testés
    nb_move::Int          # nombre de voisins acceptés (améliorants ou non)
    nb_degrad::Int        # nombre de mouvements dégradants
    nb_improve::Int       # Nombre de mouvements améliorants

    cursol::Solution      # Solution courante
    bestsol::Solution     # meilleure Solution rencontrée

    function ExploreSolver(inst::Instance)
        this=new()
        this.inst = inst
        this.nb_test = 0
        this.nb_move = 0
        this.nb_degrad = 0
        this.nb_improve = 0

        this.cursol = Solution(inst)
        ln2("Solution correspondant à l'ordre de l'instance")
        ln2(to_s(this.cursol))

        initial_sort!(this.cursol, presort=:shuffle)
        ln2("Solution initiale envoyée au solver")
        ln2(to_s(this.cursol))

        this.bestsol = Solution(this.cursol)

        return this
    end
end

function solve(sv::ExploreSolver, itermax_max::Int)
    ln2("BEGIN solve(ExploreSolver)")
    iter = 1 # car on veut faire une seule itération si on passe itermax_max=1

    ### Début du glouton  ###

    # planes_lb = zeros(Int, inst.nb_planes)
    # planes_ub = zeros(Int, inst.nb_planes)
    planes_mean_bound = zeros(inst.nb_planes)
    
    for (i, plane) in enumerate(inst.planes)
        # planes_lb[i] = plane.lb
        # planes_ub[i] = plane.ub
        planes_mean_bound[i] = (plane.lb + plane.ub)
    end
    
    # VECT = low+planes_ub # pas besoin de diviser par 2 car le tri sera le même 

    ordre = sortperm(planes_mean_bound) # ordre des avions selon la quantité (e_i+l_i)/2
    sv.cursol=ordre
    solve!(sv)

    ### Fin du glouton  ###

    lg1("iter <nb_move>=<nb_improve>+<nb_degrade> => <bestcost>")

    while iter <= itermax_max
        prevcost = sv.cursol.cost
        swap!(sv.cursol)
        println("APRES SWAP: ", to_s(sv.cursol))
        sv.nb_move += 1
        degrad = sv.cursol.cost - prevcost
        ln4("degrad=$(degrad)")
        if degrad < 0
            # Ce voisin est meilleur : on l'accepte
            lg3("+")
            sv.nb_improve += 1
            # mise a jour éventuelle de la meilleure solution
            if sv.cursol.cost < sv.bestsol.cost
                # La sauvegarde dans bestsol n'est utile que si on ne fait une descente pure
                copy!(sv.bestsol, sv.cursol)
                if lg1()
                    msg = string("\niter ", sv.nb_move, "=", sv.nb_improve, "+",
                                 sv.nb_degrad)
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
        else # degrad < 0
            # Ce voisin est plus mauvais : on l'accepte aussi (car exploration) !!
            sv.nb_degrad += 1
            if Args.get(:level) in 3:3
                print("-")
            end
            if lg4()
                msg = string("\n     ", sv.nb_move, ":", sv.nb_improve, "+/",
                             sv.nb_degrad, "- cursol=", to_s(sv.cursol) )
                print(msg)
            end
        end
        iter += 1
    end  # while iter
    ln2("\nEND solve(ExploreSolver)")
end
