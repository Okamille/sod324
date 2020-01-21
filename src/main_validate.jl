function main_validate(args)
    ln2("="^70)
    ln2("main_validate: BEGIN")

    # Résolution de l'action
    ln1("main_validate: fichier d'instance : $(args[:infile])")
    inst = Instance(args[:infile])
    
    ln1("main_validate: fichier de la solution : $(args[:solfile])")
    sol = Solution(inst, args[:solfile])

    ln1("main_validate: examen de la solution (par get_viol_description)")
    nbviols, violtxt = get_viol_description(sol)

    if nbviols == 0
        msg = "Solution correcte de coût : $(sol.cost)"
        println(to_sc(msg, :GREEN))
        ln3(to_s(sol))
    else
        msg = "Solution incorrecte : il y a $nbviols erreurs !"
        println(to_sc(msg, :RED))
        ln1(violtxt)
        ln3(to_s(sol))
    end

    ln1("main_validate: END")
    ln2("="^70)
end
