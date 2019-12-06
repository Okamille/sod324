
# # Quelques variables globale pour émuler les variables  de class en POO
# current_plane_id = 0

# Encapsule les données d'un avion
# - id: numéro interne commençant en 1, Utilisé pour l'indexation des vecteurs
# - name: nom arbitraire, par exemple le numéro commençant en "p1", "p2", ...
#   Mais pour l'instant, c'est un entier pour être conforme à ampl
# - kind: le type de l'avion (car kind est un mot clé réservé en julia !)
# - lb, target, ub: les heures mini, souhaitées et maxi d'atterrissage
# - g (et éventuellement h) les coefficients de pénalité unitaires
#   En cas d'absence du paramètre g, on utilisera h pour affecter g
#   ATTENTION : g NE SERA PAS ENCORE EXPLOITER DANS L'OPTIMISATION
#
# ATTENTION : l'appelant devra mettre à jour les attributs dérivés en appelant : 
#    update_costs!.(this.planes)
# 
mutable struct Plane
    id::Int
    name::AbstractString
    kind::Int
    at::Int # appearing time
    lb::Int # lowest bound = lowest time
    target::Int
    ub::Int # upper bound = upper time
    ep::Float64 # earliness penalty
    tp::Float64 # tardiness penalty

    # les coûts associés au retard en chaque breakpoint
    # - la date est le temps absolu (entre lb et ub)
    # - le coût est le coût réel de l'avion s'il atterrit à cette date
    timecosts::Vector{Tuple{Int,Float64}}

    # Momoïsation du calul des coûts (de 1 à p.ub)
    costs::Vector{Float64}

    to_s::Function

    # Déclaration explicite d'un constructeur totalement vide
    # Plane() = new()

    function Plane()
        this = new()
        # @show this.costs
        this.timecosts = Vector{Tuple{Int,Float64}}()
        # this.times = Vector{Int}()

        # Astuce pour créer un méthode utilisable dans le style OOP
        this.to_s = function() to_s(this) end

        return this
    end
end

function nb_segments(p::Plane)
    return length(p.timecosts) - 1
end
function nb_breakpoints(p::Plane)
    return length(p.timecosts)
end


# Initialise le tableau interne des coûts
# HYP: le tableau timecosts doit être déjà défini
# -
function update_costs!(p::Plane)
    # Initialisation d'un vector [1:p.ub] avec le coût -1.0
    p.costs = fill(-1.0, p.ub)

    # Puis on précalcule les coûts des timscosts déjà connus
    for tc in p.timecosts
        p.costs[tc[1]] = tc[2]
    end
end


# construit l'attribut timecosts de l'avion connaissant les pénalités ep et tp
#
# Principe :
# nbsegments: nombre de segments à générer pour l'avance (entre p.lb et p.target)
# et pour le retard (entre p.target et p.ub).
#
# Si nbsegments vaut 1 (valeur par défaut) alors il n'y aura que trois timecosts
# (un pour lb, pour target et pour ub)
#
# Si le target coincide avec une des deux extrémités lb ou ub, alors la demi
# parabole correspondante (avance ou retard) est ignorée.
#
# Calcul des dates intermédiaire
# Que ce soit pour l'avance ou pour le retard, on détermine les dates
# intermédiaires en deux phases :
# 1. on contruit le vecteur de (nbsegments+1) breakpoints (dont lb,
#    target et ub). Ces dates sont des Float64 linéairement réparties
# 2. on arrondit les dates aux entiers les plus proches,
# 3. puis on supprime les doublons.
#
function update_timecosts_from_etp!(p::Plane; nbsegments::Int=1)

    prc = Args.args[:cost_precision]

    if nbsegments < 1
        error("nbsegments doit être un entier positif.")
    end

    empty!(p.timecosts)

    if nbsegments == 1
        cost_lb = round( p.ep*(p.target-p.lb), digits=prc) # julia07
        tc_lb = (p.lb, cost_lb)
        push!(p.timecosts, tc_lb)

        if p.lb != p.target && p.target != p.ub
            # Si target est une des extémités, on n'aura que deux timecosts
            tc_target = (p.target, 0.0)
            push!(p.timecosts, tc_target)
        end

        cost_ub = round( p.tp*(p.ub-p.target), digits=prc) # julia07
        tc_ub = (p.ub, cost_ub)
        push!(p.timecosts, tc_ub)
    else
        # Principe pour le calcul des demi-paraboles gauche et droite.
        #   - soit qep pour "quadratic earliness penality"
        #   - soit qtp pour "quadratic tardiness penality"
        # Les coûts extrèmes en lb ou ub sont identiques pour la fonction
        # linéaire en V (avec ep ou tp) ou pour la fonction quadratique
        # (avec qep et qtp).
        # Donc :
        #   t = lb => cost_lb = ep*(target-lb) = qep*(target-lb)^2
        #          => qep = ep/(target-lb)
        #   t = target => cost_target = 0.0
        #   t = ub => cost_ub = tp*(ub-target) = qtp*(ub-target)^2
        #          => qtp = tp/(ub-target)

        # On calcule et mémorise les différents timecosts

        # Traitement des pénalités d'avance
        if p.lb != p.target
            etimes = collect(linspace(p.lb, p.target, 1 + Args.args[:nbsegments]))
            etimes_int = unique(round.(Int, etimes))

            # Calcul du coef quadratique qep (early quad pen) de la demi-parabole d'avance
            qep = p.ep/(p.target-p.lb) # earliness quadratic penality

            # get_cost_e() sera un fonction provisoire !
            get_cost_e(t::Int) = round(qep*(p.target-t)^2, digits=prc)  # julia07
            for i in 1 : (length(etimes_int)-1) # sauf le dernier car target
                time = etimes_int[i]
                # println("time=$time  =>cost_e=$(get_cost_e(time))")
                push!(p.timecosts, (time, get_cost_e(time)))
            end
        end

        # Traitement spécial pour la date target
        push!(p.timecosts, (p.target, 0.0))

        if p.target != p.ub
            # Traitement des pénalités de retard
            ttimes = collect(linspace(p.target, p.ub, 1 + Args.args[:nbsegments]))
            ttimes_int = unique(round.(Int, ttimes))

            qtp = p.tp/(p.ub-p.target) # tardiness quadratic penality
            get_cost_t(t::Int) = round(qtp*(t-p.target)^2, digits=prc) # FUNCTION!!

            for i in 2 : length(ttimes_int) # sauf le premier car target
                time = ttimes_int[i]
                push!(p.timecosts, (time, get_cost_t(time)))
            end
        end
    end
end

# # construit les pénalités ep et tp de l'avion connaissant les timecosts.
# # Même s'il y a plus de 3 breakpoints, les attributs ep et tp sont calculés à
# # partir des coûts extrêmes aux dates lb, target et ub à partir des hypothèses
# # suivantes :
# # 1 - Les coûts correspondant à lb et à ub sont ceux des premiers
# #     et dernier timecosts
# # 2 - le coût en p.target est supposé nul (ce qui peut ne pas être le cas
# #     pour les coûts mult-breakpoints)
# #
# function update_etp_from_timecosts!(p::Plane)
#     prc = Args.args[:cost_precision]
#     lb_cost = p.timecosts[1][2]
#     ub_cost = p.timecosts[end][2]
#     # On impose un coût nul en p.target. Sinon il faudrait trouver un timecost
#     # tc tel que :
#     #    timecosts[tc][1] == p.target
#     if p.target == p.lb
#         p.ep = 0.0
#     else
#         p.ep = round(lb_cost/(p.target-p.lb), digits=prc)
#     end
#     if p.ub == p.target
#         p.tp = 0.0
#     else
#         p.tp = round(ub_cost/(p.ub-p.target), digits=prc)
#     end
# end

# Méthode Julia pour convertir tout objet en string (Merci Matthias)
function Base.show(io::IO, p::Plane)
    Base.write(io,to_s(p))
end

function get_cost_basic(p::Plane, t::Int)
    # TODO_mettre_a_jour_cost_dans_plane()
    return t < p.target ? p.ep*(p.target-t) : p.tp*(t-p.target)
end

function get_cost(p::Plane, t::Int; BIG_COST::Float64=100_011.0)
    if !(t in p.lb:p.ub)
        return BIG_COST
    elseif p.costs[t] == -1.0
        p.costs[t] = t < p.target ? p.ep*(p.target-t) : p.tp*(t-p.target)

        # # Premier accès : on mémoïse le calcul de ce coût pour cette date
        # # ASSERT: t est dans l'interval lb:ub et n'est pas sur un timecosts.
        # tc1 = p.timecosts[1]
        # for i in 2:length(p.timecosts)
        #     tc2 = p.timecosts[i]
        #     if t in tc1[1]:tc2[1]
        #         c = tc1[2] + (tc2[2]-tc1[2])*(t-tc1[1])/(tc2[1]-tc1[1])
        #         p.costs[t] = c
        #         break
        #     end
        #     tc1 = tc2
        # end
    end
    return p.costs[t]
end

# Fonction de coût quadratique croissante
# - pénalité quadratique si en retard
# - récompense quadratique si en avance
function get_cost_quad(p::Plane, t::Int) # DEPRECATED (n'est plus utilisé)
    return t < p.target ? -(t - p.target)^2 : (t - p.target)^2
end

# # Fonction de coût quadratique croissante (NON UTILISÉE)
# function get_cost_tardiness(p::Plane, t::Int)
#     return t < p.target ? 0 : (t - p.target)*p.tp
# end

# return simplement le name. e.g. "p1"
function to_s(p::Plane)
    p.name
end
# return e.g. : "[p1,p2,p3,..,p10]"
function to_s(planes::Vector{Plane})
    # string("[", join( [p.name for p in planes], "," ), "]")
    # string("[", join( (p->p.name).(planes), "," ), "]")
    string("[", join( getfield.(planes, :name), "," ), "]")
end
to_s_alp(p::Plane) = to_s_long(p, format="alp")
to_s_alpx(p::Plane) = to_s_long(p, format="alpx")

function to_s_long(p::Plane; format="alpx")
    if !(format in ["alp","alpx"])
        error("seuls les formats alp et alpx sont supportés par cette méthode")
    end
    io = IOBuffer()
    print(io, "plane ")
    print(io, lpad(p.name, 3), " ")
    print(io, lpad(p.kind, 4), " ")
    print(io, lpad(p.at, 5), " ")
    print(io, lpad(p.lb, 5), " ")
    print(io, lpad(p.target, 5), " ")
    print(io, lpad(p.ub, 5), "    ")
    if format == "alpx"
        for tc in p.timecosts
            print(io, "  ", tc[1]-p.target, " ", tc[2])
        end
        # On ajoute les attributs ep et tp en commentaire
        print(io,  " # ep=", p.ep, " tp=", p.tp)
    elseif format == "alp"
        print(io, lpad(p.ep, 4), " ")
        # if !isnan(p.tp)
        #     print(io, lpad(p.tp, 4), " ")
        # end
        print(io, lpad(p.tp, 4), " ")
    else
        error("format non supporté par cette méthode : \"$format\"")
    end
    # println(io)
    String(take!(io))
end
# Retourne un commentaire décrivant une ligne au forme alp ou alpx
# Attention : pour le projet Seqata, seul le format alp existe)
# soit: #    name  kind   at     E     T     L    ep    tp
# soit: #    name  kind   at     E     T     L    dt1 cost1   dt2 cost2 ...
# Il n'y a pas de return final
#
function to_s_alp_plane_header(;format="alpx")
    io = IOBuffer()
    print(io, "#    name  kind   at     E     T     L")
    if format == "alp"
        print(io, "    ep    tp ")
    elseif format == "alpx"
        print(io, "      delta_t1 cost1  delta_t2 cost2 ...")
    else
        error("format non supporté par cette méthode : \"$format\"")
    end
    String(take!(io))
end

# Affiche les éléments définis ( != -1) du tableau costs
# - d'une part les costs précalculés en chaque timecosts
# - d'autre part les coûts calculés sur demande pour du date arbitraire
#   (et mémoïsés)
#
function to_s_costs(p::Plane)
    io = IOBuffer()
    print(io, p.name, "=>costs[]= ")
    for t in 1:length(p.costs)
        p.costs[t] <= -1.0 && continue
        print(io, " ", t, ":", p.costs[t])
    end
    String(take!(io))
end
