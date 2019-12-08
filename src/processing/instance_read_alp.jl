
@ms include("file_util.jl")
function read_alp(inst::Instance, filename::AbstractString)
    inst.loglevel>=4 && println("read_alp BEGIN $filename")

    # Par défaut le nom d'instance sera le nom de base du fichier (sans suffixe)
    bname, ext = splitext(basename(filename))
    inst.name = bname

    # println("read_alp NON IMPLÉMENTÉE !"); exit(1)
    lines = readlines(filename)

    # On commence avec un tableau d'avions vide.
    inst.planes = Vector{Plane}()
    inst.nb_planes = 0

    # # Déclaration de la matrice de séparation des types d'avion
    # # (on attend de connaitre le nombre de types pour le créer)
    # inst.sep_mat::Matrix{Int}
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
        # line = strip(replace(line => r"#.*$" => "")) #  OK
        line = replace(line, r"#.*$" => "") |> strip # VERSION AVEC pipe |> # julia07

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
    inst.loglevel>=4 && println("read_alp END")
end

# ajoute un avion à l'instance.
#
# str contient des informations suivantes
#
#       name  type   at     E     T     L      ep    tp
# e.g :  "p1    1     1   601   709  2401     1.7  1.9"
#
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
    # inst.loglevel>=4 && println("pid=$pid => ar=$(p.at)")
    p.lb =     parse(Int, words[i+=1])
    p.target = parse(Int, words[i+=1])
    p.ub =     parse(Int, words[i+=1])

    penalstr = words[i+=1]

    # Ici, on pourra distinguer les différents formats de pénalité
    # 
    # Format simple indication des pentes ep et tp )earliness et tardiness)
    #    name  type   at     E     T     L      ep    tp
    #    name  type   at     E     T     L      ep    ep (valeurs symétriques)
    # 
    # Format sétendu indication coût en chaque breakpoint (delta_t_i cost_i)
    #    name  type   at     E     T     L      dt1 p1  dt2 p2  ... (dt_i, cost_i)
    #
    # Exemple première avion de alp01
    #    plane p1 1  55 130 156 560   10.0 10.0  # pénalités symétriques
    #    plane p1 1  55 130 156 560   -26 260.0  0 0.0  404 4040.0   # car T-E << L-T
    # 
    # Principe de l'extaction
    # 
    # On extrait dans un tableau tous les nombres contenus dans penalstr.
    # Un nombre commence éventuellement par un signe - et contient au
    # moins un chiffre et éventuellement une partie décimale.
    # Pour cela, la méthode eachmatch permet d'itérer sur le capture de chaine
    # correspondant au motif défini (par une regexp) .
    # Chaque capture contient un cette nombres d'infrmation (indices de début 
    # et de fin, ...) en particulier l'élément match qui contient la chaine capturée.
    # Le tableau words contient donc des chaines qu'il faudra convertir en 
    # entier ou en flottant selon le besoin.
    #
    # words = collect(m.match for m in eachmatch(r"-?\d+(\.\d+)?", penalstr)) # OK
    words = [m.match for m in eachmatch(r"-?\d+(\.\d+)?", penalstr)] #OK

    i = 0
    if length(words) <= 2
        # format de base : valeur absolu éventuellement assymétrique
        p.ep = parse(Float64, words[i+=1])
        if length(words) <= 1
            # cas symétrique : on impose tp := ep
            p.tp = p.ep
        else
            # cas assymétrique : on lit tp
            p.tp = parse(Float64, words[i+=1])
        end
        # ep et tp étant connu, on en déduit le vecteur timecosts correspondant
        update_timecosts_from_etp!(p::Plane)
    else
        # # format étendu : avec plusieurs break points
        # # POUR L'INSTANT, LE FORMAT alpx impose que les coûts soient de la forme :
        # #        int float  int float int float
        # # - les entiers réprésentent une avance ou un retard sur le target
        # # - les réels représentent le coût de cet avion pour cette date

        # # Le tableau doit contenir un nombre pair de mot
        # if mod(length(words), 2) != 0
        #     println("format de pénalités incorrect : $penalstr")
        #     println("Il doit contenit un nombre pair de valeurs (int float ...)")
        #     exit(1)
        # end
        # # Contiendra les coût associés aux dates relatives de l'instance
        # rel_timecosts = Vector{Tuple{Int,Float64}}()
        # i = 0 # dernier indice lu
        # while i < length(words)
        #     time = parse(Int, words[i+=1])
        #     cost = parse(Float64, words[i+=1])
        #     push!(rel_timecosts, (time, cost))
        # end
        # # On trie les timecosts par date croissante
        # # Base.sort!(rel_timecosts, by=tc->tc[1], rev=true)
        # Base.sort!(rel_timecosts, by=tc->tc[1], rev=false)

        # # On vérifie que le temps relatif 0 fait bien partie des rel_timecosts
        # if !any(tc->tc[1]==0, rel_timecosts)
        #     println("Erreur manque le coût pour la date 0 dans $str")
        #     exit(1)
        # end
        # # On vérifie que le temps extrème (lb et ub) font bien partie des rel_timecosts
        # if rel_timecosts[1][1]+p.target != p.lb
        #     @show rel_timecosts[1]
        #     println("Erreur manque le coût pour la date lb dans $str")
        #     exit(1)
        # end
        # if rel_timecosts[end][1]+p.target != p.ub
        #     @show rel_timecosts[end]
        #     println("Erreur manque le coût pour la date ub dans $str")
        #     exit(1)
        # end
        # for rtc in rel_timecosts
        #     push!(p.timecosts, (rtc[1] + p.target, rtc[2]))
        # end

        # # p.timecosts étant connu on en déduit des pénalités ep et tp
        # update_etp_from_timecosts!(p)
    end
    # plane = Plane(name, kind, lb, target, ub, ep)
    if inst.loglevel>=5 println(to_s_long(p)) end

end
