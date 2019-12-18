# Ce fichier contient des fonctions génériques (i.e. indépendant de ce projet)
# concernant la lecture, l'analyse ou la manipulation de fichiers

"""
    extract_key_val(line::AbstractString)

Extrait d'une ligne le mot clé et la (les) valeur(s) associée(s).
Une clé est composée de caractères alphanumérique standards.
La clé est séparée de sa valeur par un nombre quelconque d'espaces, de '='
ou de ':'
La valeur est une chaine arbitraire sans espaces sur les bords (ni de ':' au
début !)
Si le format est incorrect : la clé retournée est une chaine vide.

Attention pour le format alp :
  Tout ce qui suit le caractère "#" sera supprimé avant l'appel à
  cette méthode

exemple :
```
 "nb_plane 10"                        => ("nb_plane", "10")
 "  nb_plane == :10"                  => ("nb_plane", "10")

 "  plane : 21; top, # du texte;"     => ("plane", "21; top, # du texte;")
 "label  :mysymbole"                  => ("label", "mysymbole")
 "email: diam@ensta.fr  "             => ("email", "diam@ensta.fr")
 "@email: diam@ensta.fr  "            => ("", "@email: diam@ensta.fr")
```
"""
function extract_key_val(line::AbstractString)
    m = match(r"^\s*(\w+)[\s=:]+(.*?)\s*$", line)
    if m != nothing
        key =  m[1]
        val =  m[2]
        return (key,val)
    else
        return ("", strip(line))
    end
end
