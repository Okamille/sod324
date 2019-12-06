
# Supprime la 1ère ligne de motif pat du txt
function eatfirstlinewithpat(txt, pat)
    lines = split(txt, r"\n")
    for i in 1:length(lines)
        if occursin(pat,lines[i])
            deleteat!(lines, i)
            break
        end
    end
    join(lines, "\n")
end
