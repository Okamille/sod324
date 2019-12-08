@ms include("solvers/descent.jl")

function main_descent(args)
    # Résolution de l'action
    println("="^70)
    println("Début de la méthode de descente")
    inst = Instance(args[:infile])

    sv = DescentSolver(inst)

    # Voir aussi option startsol de la méthode solve
    # duration = Args.get(:duration) # CETTE OPTION N'EXISTE PAS (ou plus ;-)
    # duration = 120 # secondes
    duration = 10 # secondes
    itermax = Args.get(:itermax) # existe encore :-)
    solve(sv, durationmax=duration, nb_cons_reject_max=itermax)

    bestsol = sv.bestsol
    write(bestsol)
    print_sol(bestsol)
    println("Fin de la méthode de descente")
end

main_descent(Args.args)
