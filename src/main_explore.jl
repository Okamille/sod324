include("solvers/explore.jl")

function main_expore(args)
    println("="^70)
    println("Début de l'action explore")
    inst = Instance(args[:infile])

    sv = ExploreSolver(inst)
    itermax_default = 50*inst.nb_planes
    itermax = args[:itermax] == 0 ? itermax_default : args[:itermax]
    solve(sv, itermax)

    bestsol = sv.bestsol
    print_sol(bestsol)
    println("Fin de l'action explore")
end

main_expore(Args.args)
