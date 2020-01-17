# Quelques méthodes de manipulation de tableau/vecteur

"""
Déplacement d'un élément dans un tableau

Args:
    v: vecteur à modifier
    idx1: indice de l'élément à décaller
    idx2: indice de l'émément après déplacement

Le tableau passé en paramètre est modifié.

Returns:
    Le tableau complet

Example:
    ```
    v = collect(1:7)

    shift!(v, 7, 1)'

    => 1×7 LinearAlgebra.Adjoint{Int64,Array{Int64,1}}:

    7  1  2  3  4  5  6
    ```

See Also:

    - permutate()
    - circshift()

"""
function shift!(v::Vector{T}, idx1::Int, idx2::Int) where {T}
    if idx1<idx2
        # si idx1=2 et idx2=6
        # alors v[2,3,4,5 , 6] devient v[3,4,5,6 , 2]
        v[[idx1:idx2-1;idx2]] = v[[idx1+1:idx2;idx1]]
    else
        v[[idx2+1:idx1;idx2]] = v[[idx2:idx1-1;idx1]]
    end
    return v
end

