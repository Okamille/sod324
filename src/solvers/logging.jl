
function print_log(sv)
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
