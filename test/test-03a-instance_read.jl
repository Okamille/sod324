# Fichier simplifié car ne gère plus qu'un seul format d'instance : "alp"

# ===========
relfile = "test/data/alp_01.alp"
print("Lecture du fichier au format alp $relfile...")
inst = Instance("$APPDIR/$relfile")
@test inst.name == "alp_01_p10"
alp_alpx_str = to_s_long(inst)
# println(alp_alpx_str)
# @test length(alp_alpx_str) == 1164  # FORMAT ALPX (pour alap)
@test length(alp_alpx_str) == 750     # FORMAT ALP (pour seqata)
@test alp_alpx_str[29:43] == "name alp_01_p10"
print(" fait\n")

# ===========
print("Statistiques sur l'instance $(inst.name)... ")
@test inst.nb_planes == length(inst.planes)
@test inst.nb_planes == 10
@test inst.nb_kinds == 2
@test inst.name == "alp_01_p10"
print(" fait\n")

# ===========
print("Lecture et test du premier avion (p1)... ")
p1 = inst.planes[1]
@test p1.name == "p1"
@test to_s_alp(p1)[1:9] == "plane  p1"
@test p1.id == 1
@test p1.kind == 1
@test p1.at == 55
@test p1.lb == 130
@test p1.target == 156
@test p1.ub == 560
@test p1.ep == 10.0
@test p1.tp == 10.0
print(" fait\n")

#./
