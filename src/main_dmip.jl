@ms include("solvers/mip_discret.jl")

function main_dmip(args)
    println("="^70)
    println("Début de l'action dmip")
    inst = Instance(args[:infile])
    sv = MipDiscretSolver(inst)
    solve(sv)

    bestsol = sv.bestsol
    print_sol(bestsol)
    print("Création du fichier \"$(guess_solname(bestsol))\"... ")
    write(bestsol)
    println("FAIT !")

    println("Fin de l'action dmip")
end

main_dmip(Args.args)
