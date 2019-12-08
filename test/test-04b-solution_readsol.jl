include("../src/utils/file.jl")
include("../src/preprocessing/solution_read.jl")

args = Args.parse_commandline()
Args.set(:level, 1)
Args.set(:timing_algo_solver, :earliest)

inst = instance_build_mini10()
@test inst.nb_planes == 10


# Création de la solution vide
relfile = "test/data/alp_01.sol"
solfile = "$APPDIR/$relfile"

lg1("Solution: test de readsol pour $relfile ... ")

# 
# Test de la méthode auxiliaire parse_solfile
#

data = parse_solfile(inst, solfile)
# @show data
# @show typeof(data)

@test typeof(data) <: NamedTuple

@test length(data.has_order) == true
@test length(data.has_landings) == true
@test length(data.has_times) == true
@test data.cost == 700
@test length(data.order_names) == 10
@test length(data.landings) == 10

# Lecture du fichier solution
sol = Solution(inst, solfile)

@test length(sol.planes) == inst.nb_planes
@test sol.cost == 700

# TODO : TESTER VALIDITÉ

# try
#     sol = Solution(inst, solfile)
# catch err
#     bt = backtrace()
#     msg = sprint(showerror, err, bt)
#     @warn(msg)
# end

ln1("fait.\n")


