#!/bin/bash

# An interactive menu to make the genomics app to start from the genomeDK interactive desktop
# This script will:
# 1. Ask the user to select a course from a dropdown menu
# 2. Ask the user to select a folder where the course material will be saved
# 3. Ask the user to select the genomics app file in format .SIF
# 4. Ask the user to confirm the course and folder selection
# 5. Run the software with the selected course and folder

source ~/.bashrc

# List of course names for the dropdown menu
COURSES=("Intro_to_NGS" "Intro_to_GWAS" "Intro_to_Popgen")

# Convert the courses array into a |-separated string for zenity
COURSE_OPTIONS=$(printf "|%s" "${COURSES[@]}")
COURSE_OPTIONS=${COURSE_OPTIONS:1}

# Step 1: Show dropdown menu to select the course
COURSE=$(zenity --list \
  --title="Select a Course" \
  --text="Choose a course from the list:" \
  --column="Courses" \
  ${COURSES[@]} \
  --height=250 \
  --width=300)

# Check if the user canceled
if [[ -z "$COURSE" ]]; then
  zenity --error --text="No course selected. Exiting."
  exit 1
fi

# Show an informational message before folder selection
zenity --info \
  --title="Folder Selection" \
  --text="Please choose a folder where the course material will be saved.\nThis folder must also contain the course container genomicsapp_latest.sif,\notherwise it will be downloaded" \
  --width=300

# File browser to choose the folder with a smaller window
FOLDER=$(zenity --file-selection \
  --title="Select a Folder" \
  --directory \
  --width=500 \
  --height=400)
  
# Check if the user canceled
if [[ -z "$FOLDER" ]]; then
  zenity --error --text="No folder selected. Exiting."
  exit 1
fi

# Generate the list for the dropdown menu
dropdown_items=$(gdk-project-list | cut -f1 -d ' ' | sed '1d' | tr '\n' '|')

# Show the dialog with three input fields (two entries and one dropdown)
result=$(zenity --forms --title="Input Form" \
  --text="Please fill in the values:" \
  --add-entry="Cores (e.g. 2)" \
  --add-entry="Memory (e.g. 8)" \
  --add-entry="Hours (e.g. 2)" \
  --add-combo="Choose a project" \
  --combo-values="${dropdown_items%?}") # Remove the trailing '!'

# Check if the user canceled the dialog
if [ $? -eq 0 ]; then
  # Split the results into variables
  CORES=$(echo "$result" | cut -d'|' -f1)
  MEMORY=$(echo "$result" | cut -d'|' -f2)
  TIME=$(echo "$result" | cut -d'|' -f3)
  PROJECT=$(echo "$result" | cut -d'|' -f4)  
fi

if [[ $? -ne 0 ]]; then
  zenity --info --text="Not all resources chosen, exiting now. Try again."
  exit 1
fi

# Check if the genomicsapp_latest.sif file exists in the selected folder
if [[ ! -f "$FOLDER/genomicsapp_latest.sif" && ! -f "$FOLDER/genomicsapp_latest.SIF" ]]; then
  #Download the genomics app using singularity. Empty the cache to make room for the container
  #singularity cache clean -f
  #SINGULARITYENV_OMP_NUM_THREADS=1 singularity pull $FOLDER/genomicsapp_latest.sif docker://hdssandbox/genomicsapp

  zenity --info --text="SIF file not found\nDownload with the command\n\nSINGULARITYENV_OMP_NUM_THREADS=1 singularity pull genomicsapp_latest.sif docker://hdssandbox/genomicsapp in the folder you want to use to run the material form the genomics app."
  exit 1
fi

# Step 2: Show an informational message before folder selection
zenity --info \
  --title="Start" \
  --text="FILL THIS TEXT" \
  --width=300

mkdir -p $FOLDER/$COURSE

# Step 5: Execute the command to launch the software
# Replace `your_command` with the command you want to run
eval ' xfce4-terminal -H --default-working-directory=$FOLDER/$COURSE --command="srun --mem=${MEMORY}g --cores=$CORES --time=$TIME:00:0 --account=$PROJECT --pty singularity exec --writable-tmpfs --fakeroot --env https_proxy=$https_proxy --env http_proxy=$http_proxy --bind /tmp:/tmp --bind $(pwd)/$COURSE:/work --pwd $(pwd)/$COURSE --bind /etc/ssl/certs:/etc/ssl/certs --bind /etc/pki/ca-trust:/etc/pki/ca-trust $FOLDER/genomicsapp_latest.sif start-app -c \"$COURSE\" -p $UID" '