#!/bin/bash

###############################################################################
# GROMACS MD Simulation Automation Script
# Author: Balaji M.B.
# Description: This script automates the preparation, execution, and analysis
#              of Molecular Dynamics (MD) simulations using GROMACS.
#              It handles receptor-ligand systems, solvation, ion addition,
#              energy minimization, equilibration, production run, and common
#              analyses like RMSD, RMSF, and hydrogen bonding.
#
# Usage:
#   - Provide input files: REC.pdb, LIG.pdb, and the .mdp files.
#   - Execute the script in the directory containing the input files.
#   - The script will generate all necessary topology, configuration, and
#     trajectory files, and will run GROMACS commands automatically.
#
# Requirements:
#   - GROMACS installed and available in the environment.
#   - `GMXRC` file sourced for GROMACS environment setup.
#
# This script automates the entire MD simulation process. It assumes the
# following input files:
#   - REC.pdb: Receptor structure in PDB format.
#   - LIG.pdb: Ligand structure in PDB format.
#   - .mdp files: Simulation parameter files for energy minimization (EM),
#                 equilibration (NVT, NPT), and production (MD).
#
# Version 1.0
###############################################################################

# Function to check if required files exist
check_file() {
    if [ ! -f "$1" ]; then
        echo "Error: $1 not found!"
        exit 1
    fi
}

# Function to append text to a file
append_to_file() {
    echo -e "$1" >>"$2"
}

# Source GROMACS environment (adjust path if needed)
source /usr/local/gromacs/bin/GMXRC
if [ $? -ne 0 ]; then
    echo "Error: GROMACS environment could not be sourced."
    exit 1
fi

# Step 1: Check for required files
check_file "REC.pdb"
check_file "LIG.pdb"
check_file "ions.mdp"
check_file "EM.mdp"
check_file "NVT.mdp"
check_file "NPT.mdp"
check_file "MD.mdp"

# Step 2: Prepare the receptor structure
echo "Preparing the receptor structure..."
gmx pdb2gmx -f REC.pdb -ignh
# Select CHARMM27 force field and TIP3P water model during execution

# Step 3: Prepare the ligand structure
echo "Preparing the ligand structure..."
gmx editconf -f LIG.pdb -o LIG.gro
# Copy ligand structure into conf.gro
cp LIG.gro conf.gro

# Adjust conf.gro for ligand position based on the last line
sed -i '2s/.*/2      0.000   0.000   0.000/' conf.gro # Modify second line

# Step 4: Edit topol.top file to include ligand topology
echo "Editing topol.top to include ligand topology..."
append_to_file "; Include ligand topology\n#include \"LIG.itp\"\n" topol.top
# Add ligand below protein chain entry
sed -i '/Protein_chain_E     1/a\
LIG     1' topol.top

# Step 5: Edit lig.itp file to change molecule type
echo "Editing lig.itp to set correct molecule type..."
sed -i 's/lig_gmx2 3/LIG 3/' lig.itp

# Step 6: Create a simulation box
echo "Creating simulation box..."
gmx editconf -f conf.gro -d 1.0 -bt triclinic -o box.gro

# Step 7: Solvate the system with water
echo "Solvating the system..."
gmx solvate -cp box.gro -cs spc216.gro -p topol.top -o box_sol.gro

# Step 8: Add ions to neutralize the system
echo "Adding ions to neutralize the system..."
gmx grompp -f ions.mdp -c box_sol.gro -p topol.top -o ION.tpr
gmx genion -s ION.tpr -p topol.top -conc 0.1 -neutral -o box_sol_ion.gro

# Step 9: Energy minimization
echo "Performing energy minimization..."
gmx grompp -f EM.mdp -c box_sol_ion.gro -p topol.top -o EM.tpr
gmx mdrun -v -deffnm EM

# Step 10: Generate index file for ligand
echo "Generating index file for ligand..."
gmx make_ndx -f LIG.gro -o index_LIG.ndx <<EOF
0 & ! a H*
q
EOF

# Step 11: Generate ligand position restraints
echo "Generating ligand position restraints..."
gmx genrestr -f LIG.gro -n index_LIG.ndx -o posre_LIG.itp -fc 1000 1000 1000

# Step 12: Update topol.top with position restraint file
echo "Updating topol.top with position restraints..."
append_to_file "; Ligand position restraints\n#include \"posre_LIG.itp\"\n" topol.top

# Step 13: Create system index file
echo "Creating system index file..."
gmx make_ndx -f EM.gro -o index.ndx <<EOF
1 | 13
q
EOF

# Step 14: NVT equilibration
echo "Running NVT equilibration..."
gmx grompp -f NVT.mdp -c EM.gro -r EM.gro -p topol.top -n index.ndx -maxwarn 2 -o NVT.tpr
gmx mdrun -deffnm NVT

# Step 15: NPT equilibration
echo "Running NPT equilibration..."
gmx grompp -f NPT.mdp -c NVT.gro -r NVT.gro -p topol.top -n index.ndx -maxwarn 2 -o NPT.tpr
gmx mdrun -deffnm NPT

# Step 16: Production run (MD)
echo "Running production MD simulation..."
sed -i 's/md_run_time/500000/' MD.mdp # Adjust MD run time in MD.mdp if necessary
gmx grompp -f MD.mdp -c NPT.gro -t NPT.cpt -p topol.top -n index.ndx -maxwarn 2 -o MD.tpr
gmx mdrun -deffnm MD

# Step 17: Recenter and rewrap coordinates
echo "Re-centering and re-wrapping coordinates..."
gmx trjconv -s MD.tpr -f MD.xtc -o MD_center.xtc -center -pbc mol -ur compact <<EOF
Protein
System
EOF

# Step 18: Extract the first frame of the trajectory
echo "Extracting the first frame of the trajectory..."
gmx trjconv -s MD.tpr -f MD_center.xtc -o start.pdb -dump 0

# Step 19: Perform RMSD analysis
echo "Performing RMSD analysis..."
gmx rms -s MD.tpr -f MD_center.xtc -o rmsd.xvg
gmx rms -s MD.tpr -f MD_center.xtc -o rmsd.xvg -tu ns
xmgrace rmsd.xvg

# Step 20: Perform RMSF analysis
echo "Performing RMSF analysis..."
gmx rmsf -s MD.tpr -f MD_center.xtc -o rmsf.xvg
xmgrace rmsf.xvg

# Step 21: Hydrogen bond analysis
echo "Performing hydrogen bond analysis..."
gmx hbond -s MD.tpr -f MD_center.xtc -num hb.xvg
gmx hbond -s MD.tpr -f MD_center.xtc -num hb.xvg -tu ns
xmgrace hb.xvg

# Step 22: Radius of gyration analysis
echo "Performing radius of gyration analysis..."
gmx gyrate -s MD.tpr -f MD_center.xtc -o gyrate1.xvg
xmgrace gyrate1.xvg

# Step 23: Energy analysis
echo "Performing energy analysis..."
gmx energy -f MD.edr -o energy1.xvg
xmgrace -nxy energy1.xvg

# Completion message
echo "MD Simulation and Analysis Complete."
