
@ms include("file.jl")
function read_alp(inst::Instance, filename::AbstractString)
    lg4() && println("read_alp BEGIN $filename")

    # Par défaut le nom d'instance sera le nom de base du fichier (sans suffixe)
    bname, ext = splitext(basename(filename))
    inst.name = bname

    # println("read_alp NON IMPLÉMENTÉE !"); exit(1)
    lines = readlines(filename)

    # On commence avec un tableau d'avions vide.
    inst.planes = Vector{Plane}()
    inst.nb_planes = 0

    # Déclaration de la matrice de séparation des types d'avion
    # (on attend de connaitre le nombre de types pour le créer)
    #   inst.sep_mat::Matrix{Int}

    inst.nb_kinds = 0

    # Contrainte pour le format du fichier d'instance :
    # - les valeurs nb_planes et nb_kinds doivent être définies avant les
    #   lignes planes
    # - les avions doivent être définis avant la matrice d'écart
    # - un valeur d'écart manquante est remplacée par l'entier 0
    lid = 0
    while lid < length(lines)
        line = lines[lid+=1]
        # on supprime tous les commentaires
        # line = strip(replace(line => r"#.*$" => "")) # VERSION STANDARD OK
        line = replace(line, r"#.*$" => "") |> strip   # VARIANTE AVEC pipe "|>"

        # puis on ignore les lignes vides
        if line == ""
            continue
        end
        key,val = extract_key_val(line)
        if key == "name"
            inst.name = val
            continue
        end
        if key == "nb_planes"
            inst.nb_planes = parse(Int, val)
            continue
        end
        if key == "nb_kinds"
            inst.nb_kinds = parse(Int, val)
            # On initialise la matrice sep_map des temps de séparation
            inst.sep_mat = zeros(Int, inst.nb_kinds, inst.nb_kinds)
            continue
        end
        if key == "freeze_time"
            inst.freeze_time = parse(Int, val)
            continue
        end
        if key == "plane"
            add_plane(inst, val)
            continue
        end
        if key == "sep"
            if inst.nb_kinds == 0
                println("ERREUR : nb_kinds n'est pas encore défini !")
                println(line)
                exit(1)
            end
            m = match(r"^(\d+)\s+(\d+)\s+(\d+)$", val)
            if m == nothing
                println("ERREUR : sep: format non reconnu !")
                println(line)
                exit(1)
            end
            k1 = parse(Int, m[1])
            k2 = parse(Int, m[2])
            sep = parse(Int, m[3])
            inst.sep_mat[k1, k2] = sep
            continue
        end

    end
    if inst.nb_planes == 0 || inst.nb_kinds == 0
        println("\nERREUR read_alp : le format d'instance n'a pas pu être lue :")
        println("   $filename")
        exit(1)
    end
    lg4() && println("read_alp END")
end

"""
ajoute un avion à l'instance en construction.

str contient des informations suivantes

      name  type   at     E     T     L      ep    tp
e.g :  "p1    1     1   601   709  2401     1.7  1.9"
"""
function add_plane(inst::Instance, str::AbstractString)

    # On s'assure qu'il n'y a pas d'espace sur les bords (pour simplier
    # les tests unitaires)
    str = strip(str)

    # Le 7ième mot sera traité à part en temps que définition des pénalités
    words = split(str, r"\s+"; limit=7)
    i = 0

    p = Plane()
    push!(inst.planes, p)
    p.id =     length(inst.planes)
    p.name =   words[i+=1] # on laisse en String
    p.kind =   parse(Int, words[i+=1])
    p.at =     parse(Int, words[i+=1])
    p.lb =     parse(Int, words[i+=1])
    p.target = parse(Int, words[i+=1])
    p.ub =     parse(Int, words[i+=1])

    # Le contenu de words[i+=1] décrit les pénalités.
    penalstr = words[i+=1]

    # Pour le projet simplifié SEQATA ces pénalités sont représentés par les
    # deux flottants ep et tp (ou un seul flottant si pénalités symétrique).
    penalwords = split(penalstr, r"\s+")
    penalnumbers = parse.(Float, penalwords)

    p.ep = penalnumbers[1]
    # Dans le cas symétrique ou il n'y a qu'une seule valeur présente.
    # On impose alors à tp la même valeur que ep.
    if length(penalnumbers) < 2
        p.tp = p.ep              # version symétrique 
    else
        p.tp = penalnumbers[2]   # version assumétrique standard
    end
    
    if lg5() println(to_s_long(p)) end

end
