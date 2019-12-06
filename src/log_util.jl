# TODO : créer un module
#
# module Log
# export level, lg
# export lg0, lg1, lg2, lg3, lg4, lg5
# export ln0, ln1, ln2, ln3, ln4, ln5
# global level = 2
# ...
# end # module


# Quelques fonctions d'aide au debog (EN COURS DE MISE AU POINT)
#
# La principale fonction est lg (pour log) qui affiche ou non un message selon le
# niveau de verbosité courant avec ou sans saut de ligne selon la valeur du 
# paramètre suffix.
# Dans tous les cas, cette fonction retourne un booléen indiquant si le niveau
# de verbosité est suffisant.
#
# Le message à afficher est formé par la concaténation des arguments
# vals transformés en String (par la méthode string(...)).
# 
# Ce fichier dépend du module Args (gestion des arguments du programme)
# en particulier de la variable args[:loglevel] définisant le niveau de 
# verbosité souhaité.
# 
# Exemple d'utilisation :
# 
#   ln3("coucou")
#   => affiche  "coucou" + prefix si loglevel suffisant (ici si >= 3)
#   lg4(".")
#   => affiche un caractère "." sans saut de ligne pour illustrer une progression
#   if lg3()
#     # pré-calcul... # gros pré-calcul juste pour l'affichage qui suit
#     println("Résultat du pré-calcul")
#   end
#   lg3() n'affiche rien par lui-même, mais autorise une série d'instruction si
#         level est suffisant
#   S'écrit également :
#   lg3() && @show mavariable
#
# BUG ET DÉPENDENCES
# Pour l'instant, ces méthodes ne sont utilisables que après avoir appelé
# la méthode Args.parse_commandline() pour accéder à 
# Ceci sera à modifier (création d'un module Log paramétré de l'extérieur)
# 


# lg0(vals...) = lg(0, vals..., suffix="", doflush=true  )
lg0(vals...; kwargs... ) = lg(0, vals...; kwargs... )
lg1(vals...; kwargs... ) = lg(1, vals...; kwargs... )
lg2(vals...; kwargs... ) = lg(2, vals...; kwargs... )
lg3(vals...; kwargs... ) = lg(3, vals...; kwargs... )
lg4(vals...; kwargs... ) = lg(4, vals...; kwargs... )
lg5(vals...; kwargs... ) = lg(5, vals...; kwargs... )

ln0(vals...; kwargs... ) = lg(0, vals...; kwargs..., suffix="\n" )
ln1(vals...; kwargs... ) = lg(1, vals...; kwargs..., suffix="\n" )
ln2(vals...; kwargs... ) = lg(2, vals...; kwargs..., suffix="\n" )
ln3(vals...; kwargs... ) = lg(3, vals...; kwargs..., suffix="\n" )
ln4(vals...; kwargs... ) = lg(4, vals...; kwargs..., suffix="\n" )
ln5(vals...; kwargs... ) = lg(5, vals...; kwargs..., suffix="\n" )

function lg(minlevel::Int, vals... ;  
            prefix::String="", suffix::String="", doflush=true)
    if Args.args[:level] >= minlevel
        if !isempty(vals)
            print(prefix, join(vals, ""), suffix)
            doflush && flush(stdout)
        end
        return true
    else
        return false
    end
end

# POUR INFORMATION : Á DÉPLACER
#
# Voir aussi (capture de l'affichage d'une commande) :
#  https://stackoverflow.com/questions/54599148/in-julia-1-0-how-do-i-get-strings-using-redirect-stdout
# 
# Utilisation :
#   redirect_to_files(prefix * ".log", prefix * ".err") do
#       compute(...)
#   end
#   
# function redirect_to_files(dofunc, outfile, errfile)
#     open(outfile, "w") do out
#         open(errfile, "w") do err
#             redirect_stdout(out) do
#                 redirect_stderr(err) do
#                     dofunc()
#                 end
#             end
#         end
#     end
# end