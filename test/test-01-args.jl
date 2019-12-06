# ===========
print("Test de l'analyse des arguments passées en ligne de commande... ")

# Si le premier paramètre est inconnu (action "xxx"), on doit lever une erreur
@test_throws ArgumentError args = Args.parse_commandline("xxx")

# Si le fichier d'instance n'existe pas, on doit lever une erreur
@test_throws ArgumentError args = Args.parse_commandline("test --infile fichier_bidon.alp")


# Test de l'analyse de la chaine passée en arguments
cli = "
    explore
    --infile $APPDIR/test/data/alp_01.alpx
    --loglevel 2
    --presort shuffle
    -L0
    -n100
    -d/tmp
"
args = Args.parse_commandline(cli)

# On vérifier que to_s_dict(args) retourne bien le dict des arguments
# Args.show_dict(args)
# println(Args.to_s_dict(args))
@test occursin(r"\spresort\s*=>\s*shuffle\s", Args.to_s_dict(args))

# Test d'accès aux arguments via le dict
@test  args[:infile] == "$APPDIR/test/data/alp_01.alpx"
@test  args[:level] == 0

# Test d'accès aux arguments via l'accesseur
@test  Args.get(:level) == args[:level]
@test  Args.get("level") == args[:level]

# Test de la modification d'un arguments
Args.set(:level, 3)
@test  args[:level] == 3
@test  Args.get(:level) == args[:level]
@test  Args.get("level") == args[:level]

Args.set(:level, 0) # Pour rendre les tests suivants silencieux !

print("ok\n")
