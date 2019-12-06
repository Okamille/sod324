# Quelques fonctions ou macros utiles en mode interactif
# (dont des alias courts pour les types ou les méthodes)

# Raccourci pour la gestion des options (Args)
as(sym::Symbol, val) = Args.set(sym, val)
ag(sym::Symbol, val) = Args.set(sym, val)
ag(sym::Symbol)      = Args.get(sym)

# Raccourci pour la gestion du level (pour les messages d'erreur)
lv(L) = Args.set(:level, L)
lv() = Args.get(:level)

p = println
pn = print
# inc=include

data = dirname(dirname(@__FILE__)) * "/data"

# Les chemins d'instance (String)
p01="$data/alp_01_p10.alp"
p02="$data/alp_02_p15.alp"
p03="$data/alp_03_p20.alp"
p04="$data/alp_04_p20.alp"
p05="$data/alp_05_p20.alp"
p06="$data/alp_06_p30.alp"
p07="$data/alp_07_p44.alp"
p08="$data/alp_08_p50.alp"
p09="$data/alp_09_p100.alp"
p10="$data/alp_10_p150.alp"
p11="$data/alp_11_p200.alp"
p12="$data/alp_12_p250.alp"
p13="$data/alp_13_p500.alp"

# i01=Instance("$data/alp_01_p10.alp")
# i02=Instance("$data/alp_02_p15.alp")
# i03=Instance("$data/alp_03_p20.alp")
# i04=Instance("$data/alp_04_p20.alp")
# i05=Instance("$data/alp_05_p20.alp")
# i06=Instance("$data/alp_06_p30.alp")
# i07=Instance("$data/alp_07_p44.alp")
# i08=Instance("$data/alp_08_p50.alp")
# i09=Instance("$data/alp_09_p100.alp")
# i10=Instance("$data/alp_10_p150.alp")
# i11=Instance("$data/alp_11_p200.alp")
# i12=Instance("$data/alp_12_p250.alp")
# i13=Instance("$data/alp_13_p500.alp")
i01=Instance(p01)
i02=Instance(p02)
i03=Instance(p03)
i04=Instance(p04)
i05=Instance(p05)
i06=Instance(p06)
i07=Instance(p07)
i08=Instance(p08)
i09=Instance(p09)
i10=Instance(p10)
i11=Instance(p11)
i12=Instance(p12)
i13=Instance(p13)

# cam=generate_mutations


#./
