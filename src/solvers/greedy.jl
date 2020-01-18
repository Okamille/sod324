"""
Renvoie un solution triée par ordre d'atterrissage.

Les contraintes de séparation de deux avions consécutifs sont respectées.

Return:
    Solution
"""
function greedy(instance::Instance)
    n = instance.nb_planes

    targets = [plane.target for plane in instance.planes]

    σ = sortperm(targets)
    sorted_planes = instance.planes[σ]
    targets = targets[σ]

    sep = [get_sep(instance, sorted_planes[i], sorted_planes[i+1])
        for i in 1:n-1]

    println(targets)
    println(sep)

    x = zeros(Int, n)
    x[1] = targets[1]
    for i=2:n
        # dans l'idéal il faudrait boucler sur TOUS les avions précédant i,
        # car on peut respecter la distance avec i-1 mais pas i-2 par exemple
        x[i] = max(targets[i], x[i-1] + sep[i-1])
    end
    return Solution(instance, sorted_planes, x)
end