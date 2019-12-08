include("../src/preprocessing/instance_generators.jl")

args = Args.parse_commandline()
Args.set(:level, 1)

# inst = Instance(Args.get(:infile))
print("Génération d'une instance... ")

inst = instance_build_mini10()

if lg2()
    println("\n", to_s_alpx(inst))
    print("Génération d'une instance... ")
end
print("=> fait\n")

print("Statistiques sur l'instance $(inst.name)... ")
@test inst.nb_planes == length(inst.planes)
@test inst.nb_planes == 10
@test inst.nb_kinds == 2
@test inst.name == "mini10"
print("=> fait\n")


