
# # Quelques variables globale pour émuler les variables  de class en POO
# current_plane_id = 0

"""
Encapsule les données d'un avion.

Args:
    id (Int): numéro interne commençant en 1, Utilisé pour l'indexation des vecteurs
    name (AbstractString): nom arbitraire, par exemple le numéro commençant en "p1", "p2", ... Mais pour l'instant, c'est un entier pour être conforme à ampl
    kind (Int): le type de l'avion (car kind est un mot clé réservé en julia !)
    lb (Int): heure minimale d'atterrissage
    target (Int): heure souhaitée d'atterrissage
    ub (Int): heure maximale d'atterrissage
    ep (Float64): earliness penalty
    tp (Float64): tardiness penalty

Attention:
    L'appelant devra mettre à jour les attributs dérivés en appelant :  ``update_costs!.(this.planes)``
"""
mutable struct Plane
    id::Int
    name::AbstractString
    kind::Int
    at::Int
    lb::Int
    target::Int
    ub::Int
    ep::Float64
    tp::Float64

    # Momoïsation du calul des coûts (de 1 à p.ub)
    costs::Vector{Float64}
end

function Plane(id::Int, name, kind::Int, at::Int, lb::Int, target::Int, ub::Int,
               ep::Float64, tp::Float64)
    costs = fill(-1.0, ub)
    return Plane(id, name, kind, at, lb, target, ub, ep, tp, costs)
end


"""Méthode Julia pour convertir tout objet en string (merci Matthias)."""
function Base.show(io::IO, p::Plane)
    Base.write(io, to_s(p))
end

"""
Retourne le coût de l'avion en fonction de la data d'atterrissage `t`.

Ne tient pas compt de la fenêtre d'atterrissage de l'avion.
"""
function get_cost_basic(p::Plane, t::Int)
    return t < p.target ? p.ep*(p.target-t) : p.tp*(t-p.target)
end

"""Retourne le coût de l'avion en fonction de la data d'atterrissage `t`."""
function get_cost(p::Plane, t::Int; BIG_COST::Float64=100_011.0)
    if !(t in p.lb:p.ub)
        return BIG_COST
    elseif p.costs[t] == -1.0
        p.costs[t] = t < p.target ? p.ep * (p.target-t) : p.tp * (t-p.target)
    end
    return p.costs[t]
end

"""Retourne le nom de l'avion."""
function to_s(p::Plane)
    p.name
end

"""Retourne les noms des avions du vecteur."""
function to_s(planes::Vector{Plane})
    # string("[", join( [p.name for p in planes], "," ), "]")
    # string("[", join( (p->p.name).(planes), "," ), "]")
    string("[", join( getfield.(planes, :name), "," ), "]")
end
to_s_alp(p::Plane) = to_s_long(p) 
# to_s_alp(p::Plane) = to_s_long(p, format="alp")
# to_s_alpx(p::Plane) = to_s_long(p, format="alpx")

function to_s_long(p::Plane)
    io = IOBuffer()
    print(io, "plane ")
    print(io, lpad(p.name, 3), " ")
    print(io, lpad(p.kind, 4), " ")
    print(io, lpad(p.at, 5), " ")
    print(io, lpad(p.lb, 5), " ")
    print(io, lpad(p.target, 5), " ")
    print(io, lpad(p.ub, 5), "    ")
    print(io, lpad(p.ep, 4), " ")
    print(io, lpad(p.tp, 4), " ")
    String(take!(io))
end

"""
Décrit une ligne au forme alp ou alpx.

Attention : pour le projet Seqata, seul le format alp existe)

    - soit: `name  kind   at     E     T     L    ep    tp`

    - soit: `name  kind   at     E     T     L    dt1 cost1   dt2 cost2 ...`

Il n'y a pas de return final.
"""
function to_s_alp_plane_header()
    io = IOBuffer()
    print(io, "#    name  kind   at     E     T     L")
    print(io, "    ep    tp ")
    String(take!(io))
end

"""Affiche les éléments définis ( != -1 ) du tableau costs."""
function to_s_costs(p::Plane)
    io = IOBuffer()
    print(io, p.name, "=>costs[]= ")
    for t in 1:length(p.costs)
        p.costs[t] <= -1.0 && continue
        print(io, " ", t, ":", p.costs[t])
    end
    String(take!(io))
end
