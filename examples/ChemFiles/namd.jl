#
# Protein - TMAO
#

using MDDF

# Ploting  
using Plots
ENV["GKSwstype"]="nul" # This supresses the need of a display while plotting

# Here we use the PDBTools package to read the pdb file and select the
# solute and solvent atoms (from http://github.com/m3g/PDBTools)
using PDBTools
atoms = PDBTools.readPDB("../NAMD/structure.pdb")

# The solute is a single protein molecule (infinte dilution case). In this case,
# use the option nmols=1
solute_indexes = PDBTools.selindex(atoms,"protein")
solute = MDDF.Selection( solute_indexes, nmols=1 )

# The solvent is TMAO, which has 14 atoms. Use the natomspermol to indicate how many
# atoms each molecule has, such that there is no ambiguity on how to split the coordinates 
# of the selection into individual molecules.
solvent_indexes = PDBTools.selindex(atoms,"resname TMAO")
solvent = MDDF.Selection( solvent_indexes, natomspermol=14 )

# Input options for the calcualtion
options = MDDF.Options(binstep=0.2)

# Run MDDF calculation, and get the resutls in the R structure. Here we use the
# Chemfiles package to read the trajectory. This package reads the trajectories
# in many common simulation formats
trajectory = MDDF.ChemFile("../NAMD/trajectory.dcd",solute,solvent)
@time R = MDDF.mddf(trajectory,options)

plot(layout=(6,1))

sp=1
plot!(ylabel="MDDF",subplot=sp)
plot!(R.d,R.mddf,subplot=sp,label="mddf")
plot!(R.d,R.rdf,subplot=sp,label="rdf")
plot!(legend=:topright,subplot=sp)

sp=2
plot!(ylabel="KB",subplot=sp)
plot!(R.d,R.kb,subplot=sp,label="mddf")
plot!(R.d,R.kb_rdf,subplot=sp,label="rdf")
plot!(legend=:topright,subplot=sp)

sp=3
plot!(ylabel="Count",subplot=sp)
scatter!(R.d,R.md_count,subplot=sp,label="md")
scatter!(R.d,R.md_count_random,subplot=sp,label="rand")

sp=4
plot!(ylabel="Shell vol", subplot=sp)
plot!(R.d,R.volume.shell,subplot=sp,label="")

sp=5
plot!(ylabel="Sum MD", subplot=sp)
scatter!(R.d,R.sum_md_count,subplot=sp,label="md")

sp=6
plot!(ylabel="Sum RAND", subplot=sp)
scatter!(R.d,R.sum_md_count_random,subplot=sp,label="rand")
scatter!(R.d,R.sum_rdf_count,subplot=sp,label="rdf")
plot!(legend=:topleft,subplot=sp)

plot!(size=(800,1300))
savefig("./plots.pdf")
