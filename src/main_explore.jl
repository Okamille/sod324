include("solvers/explore.jl")

function main_expore(args)
    println("="^70)
    println("Début de l'action explore")
    inst = Instance(args[:infile])

    sv = ExploreSolver(inst)
    itermax_default = 50*inst.nb_planes
    itermax = args[:itermax] == 0 ? itermax_default : args[:itermax]

    ms_start = ms() # seconde depuis le démarrage avec précision à la ms
    solve(sv, itermax)
    ms_stop = ms()

    bestsol = sv.bestsol
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

    println("Fin de l'action explore")
end

main_expore(Args.args)
