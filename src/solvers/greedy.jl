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
    x = zeros(Int, n)
    x[1] = targets[1]
    for i=2:n
        # dans l'idéal il faudrait boucler sur TOUS les avions précédant i,
        # car on peut respecter la distance avec i-1 mais pas i-2 par exemple
        x[i] = max(targets[i], x[i-1] + sep[i-1])
    end
    return Solution(instance, sorted_planes, x)
end

function greedy!(sol::Solution; presort=:ARGS)
    n = sol.inst.nb_planes
    initial_sort!(sol, presort=presort, solve=false)

    sep = [get_sep(sol.inst, first_plane, second_plane)
           for (first_plane, second_plane) in zip(sol.planes[1:end-1], sol.planes[2:end])]

    sol.x[1] = sol.planes[1].target
    for i=2:n
        sol.x[i] = max(sol.planes[i].target, sol.x[i-1] + sep[i-1])
    end
    update_costs!(sol)
end
