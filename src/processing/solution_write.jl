"""Utils to process solutions."""

"""Writes a solution to a file."""
function write_solution(solution)
    name = solution.instance.name

    path = joinpath(APPDIR, "sols", "$name=$(solution.cost).sol")
    open(path, "w") do io
        println(io, "name $name")
        println(io, "timestamp $(Dates.DateTime(now()))")
        println(io, "cost $(solution.cost)")
        println(io, "order $planes")
        println(io, "")
        println(io, "#       name     t   dt  cost ")

        for (plane, landing_time, cost) in zip(planes, solution.x, solution.costs)
            println(io,
                    "landing     $plane $landing_time $(landing_time-plane.target) $cost")
        end
    end
end
