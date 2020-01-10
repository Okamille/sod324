@ms include("descent_solver.jl")

function main_descent(args)
    # Résolution de l'action
    println("="^70)
    println("Début de la méthode de descente")
    inst = Instance(args[:infile])

    sv = DescentSolver(inst)

    # Voir aussi option startsol de la méthode solve
    # duration = Args.get(:duration) # CETTE OPTION N'EXISTE PAS (ou plus ;-)
    # duration = 120 # secondes
    # duration = 20 # secondes
    duration = 300 # secondes
    itermax = Args.get(:itermax) # existe encore :-)
    ms_start = ms() # seconde depuis le démarrage avec précision à la ms
    solve(sv, durationmax=duration, nb_cons_reject_max=itermax)
    ms_stop = ms()

    bestsol = sv.bestsol
    write(bestsol)
    print_sol(bestsol)

    nb_calls = bestsol.solver.nb_calls
    nb_infeasable = bestsol.solver.nb_infeasable
    nb_sec = round(ms_stop - ms_start, digits=3)
    nb_call_per_sec = round(nb_calls/nb_sec, digits=3)
    println("Performance: ")
    println("  nb_calls=$nb_calls")
    println("  nb_infeasable=$nb_infeasable")
    println("  nb_sec=$nb_sec")
    println("  => nb_call_per_sec = $nb_call_per_sec call/sec")

    println("Fin de la méthode de descente")
end

main_descent(Args.args)
