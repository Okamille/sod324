# Quelques fonctions ou macros utiles en mode interactif
# (dont des alias courts pour les types ou les méthodes)

# Raccourci pour la gestion des options (Args)
as(sym::Symbol, val) = Args.set(sym, val)
ag(sym::Symbol, val) = Args.set(sym, val)
ag(sym::Symbol)      = Args.get(sym)
ag()                 = Args.show_args()

# Raccourci pour la gestion du level (pour les messages d'erreur)
lv(L) = Args.set(:level, L)
lv() = Args.get(:level)

p = println
pn = print
# inc=include

data = dirname(dirname(@__FILE__)) * "/data"

# Les chemins d'instance (String)
p01="$data/alp_01_p10.alp"
p02="$data/alp_02_p15.alp"
p03="$data/alp_03_p20.alp"
p04="$data/alp_04_p20.alp"
p05="$data/alp_05_p20.alp"
p06="$data/alp_06_p30.alp"
p07="$data/alp_07_p44.alp"
p08="$data/alp_08_p50.alp"
p09="$data/alp_09_p100.alp"
p10="$data/alp_10_p150.alp"
p11="$data/alp_11_p200.alp"
p12="$data/alp_12_p250.alp"
p13="$data/alp_13_p500.alp"

i01=Instance(p01)
i02=Instance(p02)
i03=Instance(p03)
i04=Instance(p04)
i05=Instance(p05)
i06=Instance(p06)
i07=Instance(p07)
i08=Instance(p08)
i09=Instance(p09)
i10=Instance(p10)
i11=Instance(p11)
i12=Instance(p12)
i13=Instance(p13)

# Macro @i pour simplifier les "include" en interactif
# Exemple d'itilisation :
#    @i "04" "05"
# Recherche tous les fichiers correspondant à la gpatternes *04* et *05*
# puis les recharges par include (dans l'ordre)
# Recherche d'abord dans le répertoire racine, puis dans src/ puis dans test/
# 
# ASTUCE : 
# Si les arguments sont purement alphanumériques, alors on peut éviter des 
# guillemets 
#   @i inst       ok
#   => charge tous les fichiers contenant "inst" dans src/ ou dans test/
#   @i  src/inst   KO  
#   @i "src/inst"  ok
#   @i  04         KO (car est équivalent à @i "4" qui couvre plus large)
#   @i "04"        ok
# 
macro i(pats...)
    files = get_files_from_pats(pats...)

    if length(files) == 0
        println("Aucun fichier ne correspond.")
    else
        for absfile in files
            relfiles = replace(absfile, "$APPDIR/" => "")
            println("### include file: \"", relfiles, "\" ...")
            include(absfile)
            println("### include file: \"", relfiles, "\" FAIT")
            # println("include done.")
        end
    end
end

# macro f (find)
# Affiche les fichiers correspondants aux patternes passées (avec date de modif)
macro f(pats...)
    files = get_files_from_pats(pats...)
    wd = pwd(); cd(APPDIR)
    # On rend le chemin des fichiers relatifs par rapport au projet pour
    # alléger le listing (quelque soit le répertoire courant)
    files = replace.(files, "$APPDIR/" => "")
    for file in files
        run(`ls -l $file`)
    end
    cd(wd)
end

function get_files_from_pats(pats...)
    # @show typeof(pats)
    # @show pats
    files = []
    for pat in pats
        append!(files, glob("$pat", "$APPDIR") )
        append!(files, glob("*$pat*", "$APPDIR") )
        append!(files, glob("*$pat*", "$APPDIR/src") )
        append!(files, glob("*$pat*", "$APPDIR/test") )
    end
    return files
end
#./
