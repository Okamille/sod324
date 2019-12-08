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

function solve(s::ExploreSolver, itermax_max::Int)
    ln2("BEGIN solve(ExploreSolver)")
    itermax = 1 # car on veut faire une seule itération si on passe itermax_max=1

    lg1("iter <nb_move>=<nb_improve>+<nb_degrade> => <bestcost>")

    while itermax <= itermax_max
        prevcost = s.cursol.cost
        swap!(s.cursol)
        # println("APRES SWAP: ", to_s(s.cursol))
        s.nb_move += 1
        degrad = s.cursol.cost - prevcost
        ln4("degrad=$(degrad)")
        if degrad < 0
            # Ce voisin est meilleur : on l'accepte
            lg3("+")
            s.nb_improve += 1
            # mise a jour éventuelle de la meilleure solution
            if s.cursol.cost < s.bestsol.cost
                # La sauvegarde dans bestsol n'est utile que si on ne fait une descente pure
                copy!(s.bestsol, s.cursol)
                if lg1()
                    msg = string("\niter ", s.nb_move, "=", s.nb_improve, "+",
                                 s.nb_degrad)
                    if lg2()
                        # affiche coût + ordre des avions
                        msg *= string(" => ", to_s(s.bestsol))
                    else
                        # affiche seulement le coût
                        msg *= string(" => ", ts.bestsol.cost)
                    end
                    print(msg)
                end
            end
        else # degrad < 0
            # Ce voisin est plus mauvais : on l'accepte aussi (car exploration) !!
            s.nb_degrad += 1
            if Args.get(:level) in 3:3
                print("-")
            end
            if lg4()
                msg = string("\n     ", s.nb_move, ":", s.nb_improve, "+/",
                             s.nb_degrad, "- cursol=", to_s(s.cursol) )
                print(msg)
            end
        end
        itermax += 1
    end  # while itermax
    ln2("\nEND solve(ExploreSolver)")
end
