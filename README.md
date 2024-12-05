# GROMACS MD Simulation Automation Script

This repository provides an automation script to run Molecular Dynamics (MD) simulations using GROMACS. The script automates the process of preparing the system, running energy minimization, equilibration (NVT and NPT), production MD simulation, and analyzing common properties like RMSD, RMSF, hydrogen bonds, and energy.

## Requirements

### 1. **GROMACS**
   - GROMACS is required to run the MD simulations.
   - **Version**: GROMACS 2021.3 or higher is recommended.
   - **Installation**: You can install GROMACS on Ubuntu using the following command:
     ```bash
     sudo apt install gromacs
     ```
     Alternatively, if GROMACS is manually compiled, make sure to source the GROMACS environment:
     ```bash
     source /usr/local/gromacs/bin/GMXRC
     ```

### 2. **Input Files**
   - **REC.pdb**: The receptor structure in PDB format.
   - **LIG.pdb**: The ligand structure in PDB format.
   - **MDP Files**: Parameter files for simulation stages:
     - `ions.mdp` (ions addition)
     - `EM.mdp` (energy minimization)
     - `NVT.mdp` (NVT equilibration)
     - `NPT.mdp` (NPT equilibration)
     - `MD.mdp` (production MD run)
   - **LIG.itp**: The topology file for the ligand. You can obtain this file from **SwissParam**, a web-based tool for generating topology files for small molecules:
     - Visit [SwissParam](http://www.swissparam.ch/) to generate the ligand's topology file.
     - Once you input your ligand's structure, download the generated `LIG.itp` file and place it in the same directory as the script.

### 3. **Operating System**
   - The script is developed for **Ubuntu** or other Linux distributions.
   - It can be adapted for **macOS** or other Unix-like systems by making adjustments to file paths or commands if necessary.

### 4. **Dependencies**
   - **Bash**: The script is written in Bash and should be executed in a Unix-like shell environment.
   - **Text Editor**: Modify `.mdp` and `.top` files using a text editor like `gedit`, `nano`, or `vim`.
   - **xmgrace**: For visualizing output data files (`.xvg`). Install it with:
     ```bash
     sudo apt install grace
     ```

### 5. **System Requirements**
   - **RAM**: 8GB or more is recommended, depending on the size of the system being simulated.
   - **Disk Space**: Ensure adequate space (at least 10GB or more) for the simulation and analysis files, especially for large trajectory files.

### 6. **Optional Analysis Tools**
   - **xmgrace**: For plotting and visualizing the output `.xvg` files like RMSD, RMSF, and energy logs.
     - Install using:
       ```bash
       sudo apt install grace
       ```

## Usage

### 1. **Prepare Your Input Files**
   - Place the following files in the same directory as the script:
     - `REC.pdb` (receptor structure in PDB format)
     - `LIG.pdb` (ligand structure in PDB format)
     - `ions.mdp`, `EM.mdp`, `NVT.mdp`, `NPT.mdp`, `MD.mdp` (simulation parameter files)
     - `LIG.itp` (ligand topology file, obtained from [SwissParam](http://www.swissparam.ch/))

### 2. **Run the Script**
   - Make the script executable:
     ```bash
     chmod +x MD_simulation_automation.sh
     ```
   - Execute the script:
     ```bash
     ./MD_simulation_automation.sh
     ```
   - The script will automatically generate all necessary files, run GROMACS commands, and perform MD simulations and analysis.

### 3. **Review Results**
   - Once the simulation completes, the output files will be available in the current directory:
     - `rmsd.xvg` (RMSD plot)
     - `rmsf.xvg` (RMSF plot)
     - `hb.xvg` (Hydrogen bond analysis)
     - `gyrate1.xvg` (Radius of gyration analysis)
     - `energy1.xvg` (Energy analysis)
     - Various `.gro`, `.xtc`, `.tpr` files representing simulation progress

   - Open `.xvg` files using **xmgrace** for graphical analysis:
     ```bash
     xmgrace rmsd.xvg
     ```

