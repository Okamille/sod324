# Quelques méthodes ou macros utilitaires personnelles
# (indépendantes de tout projet julia)
# Modif le 21/11/2019 

"""
    ms()

démarre le chrono si nécessaire (la première fois) et retourne la durée
écoulée depuis ce démarrage (à la milli-seconde prêt)
"""
function ms()
    global MS_START
    if ! @isdefined MS_START
        MS_START = time()
    end
    ms = round(Int, 1000*(time() - MS_START))
    return (ms/1000)
end

function ms_reset()
    global MS_START = time()
end

"""
    @ms(cmd)

chronomètre l'exécution d'une commande :
- affiche la durée depuis le lancement du programme (peut-être long en
  mode interactife !)
- affiche le fichier depuis lequel elcette macro est appelée
- affiche la commande à exécuter
- exécute cette commande
- affiche la durée d'exécution sur la ligne suivante

Exemple d'affichage en interactif :
```
@ms sleep(1)
=>
@ms TODO 9349.527s (mode repl):sleep(1) ... 
@ms done 9350.552s (mode repl):sleep(1) en 1.002s
```

Exemples depuis en script :
```
@ms using JuMP
=>
@ms TODO 0.871s (mode repl):using JuMP ... 
@ms done 2.198s (mode repl):using JuMP en 1.327s
```
"""
macro ms(cmd)
    cmdstr = string(cmd)
    # info sur le fichier qui a appelé cette macro
    if isinteractive()
        # mode interactif => pas de fichier d'appel
        fileinfo = "(mode repl)"
    else
        # On récupère le nom relatif du fichier qui a appellé cette macro
        fname = string(__source__.file)
        fname = fname[length("$APPDIR")+2 : end]
        # On récupère le numéro de ligne de l'appel
        fline = string(__source__.line)
        fileinfo = "$(fname):$fline"
    end
     
    quote
        # la notation $(cmd) est réservée dans un environnement quote
        local t0 = time()
        # println("@ms ", round(ms(), digits=3), "s ", $fileinfo, ":", $(cmdstr), " ... ") # ok 21/11/2019
        print("@ms TODO ", round(ms(), digits=3), "s ", $fileinfo, ":", $(cmdstr)) 
        println(" ... ") 
        local val = $(esc(cmd)) # <= EXECUTION DU CALCUL Á CHRONOMÉTRER
        local t1 = time()
        # println("    => fait en ", round(t1-t0, digits=3), "s", " total=", ms(), "s")
        print("@ms done ", round(ms(), digits=3), "s ", $fileinfo, ":", $(cmdstr)) 
        println(" en ", round(t1-t0, digits=3), "s")
        val
    end
end
# On démarre le chronomètre
ms()
