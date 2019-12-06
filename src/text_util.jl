

# findall cherche toutes les rexexp dans une chaine
# (devrait apparaitre avec cette API dans julia-1.3
#
# Exemple d'utilisation
#   findall("ing", "Spinning laughing dancing")
#   =>
#   3-element Array{UnitRange{Int64},1}:
#    6:8
#    15:17
#    23:25
#
#   txt "Spinning laughing dancing"
#   rpat = r"\w+"
#   ranges = [txt[r] for r in findall(rpat, txt)]
#   map(r->s[r], ranges)
#   =>
#   3-element Array{String,1}:
#    "Spinning"
#    "laughing"
#    "dancing"
#
#   txt "Spinning laughing dancing"
#   rpat = r"\w+"
#   words = [txt[r] for r in findall(rpat, txt)]
#   =>
#   3-element Array{String,1}:
#    "Spinning"
#    "laughing"
#    "dancing"
#
if !hasmethod(Base.findall, Tuple{Regex, String})
    # Julia pas assez récent (< julia-1.3)
    @info "On définit : Base.findall pour Tuple{Regex, String}"
    function Base.findall(t::Union{AbstractString,Regex}, s::AbstractString;
                     overlap::Bool=false)
        found = UnitRange{Int}[]
        i, e = firstindex(s), lastindex(s)
        while true
            r = findnext(t, s, i)
            isnothing(r) && return found
            push!(found, r)
            j = overlap || isempty(r) ? first(r) : last(r)
            j > e && return found
            @inbounds i = nextind(s, j)
        end
    end
else
    @info "Déjà définie : Base.findall pour Tuple{Regex, String}"
end

#./

