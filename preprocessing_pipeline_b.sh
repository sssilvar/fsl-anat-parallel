#!/usr/bin/env bash

IMAGE=$1  # Image to be processed
SUBJECT_FOLDER=$2
MNI_TEMPLATE="/usr/local/fsl/data/standard/MNI152_T1_1mm_brain.nii.gz"  # MNI152 brain template

# Usage message
USAGE="USAGE:\n\t- preprocessing_pipeline_b.sh [IMAGE_TO_BE_PROCESSED]  [SUBJECT_FOLDER]"
if [[ ! ${IMAGE} ]]; then
    echo "[  ERROR  ] Image to be processed not defined."
    echo -e ${USAGE}
    exit 1
fi

if [[ ! ${SUBJECT_FOLDER} ]]; then
    echo "[  ERROR  ] Subject folder is not defined."
    echo -e ${USAGE}
    exit 1
fi

# =============================================
# START PIPELINE
# =============================================
# Up to bias correction and BET
echo "======== FSL ANAT (BIAS + BET) ========"
eval "fsl_anat -i ${IMAGE} -o ${SUBJECT_FOLDER} --noseg --nosubcortseg"
SUBJECT_FOLDER="${SUBJECT_FOLDER}.anat"
STRIPPED_BRAIN="${SUBJECT_FOLDER}/T1_biascorr_brain.nii.gz"

# Intensity normalization
echo "======== INTENSITY NORMALIZATION ========"
INM_BRAIN="${SUBJECT_FOLDER}/mprage_Correc.nii.gz"  # Intensity normalized volume
eval "fslmaths ${STRIPPED_BRAIN} -inm 60 ${INM_BRAIN}"

# Rigid egistration
echo "======== RIGID REGISTRATION ========"
REGISTERED="${SUBJECT_FOLDER}/Cer_Registrado.nii.gz"
TRANSF_MAT="${SUBJECT_FOLDER}/Cer_Registrado.mat"
#eval "flirt -in ${MNI_TEMPLATE} -ref ${INM_BRAIN} -out ${REGISTERED} -omat ${TRANSF_MAT} -dof 12"

# Elastic registration
echo "======== ELASTIC REGISTRATION ========"
REGISTERED="${SUBJECT_FOLDER}/Cer_Registrado_Elastico.nii.gz"
WARP_COUT="${SUBJECT_FOLDER}/Elastic_Cout.nii.gz"
eval "fnirt --ref=${INM_BRAIN} --in=${MNI_TEMPLATE} --iout=${REGISTERED} --aff=${TRANSF_MAT} --cout=${WARP_COUT} --splineorder=2 --imprefm=0 --impinm=0"

# Segmentation
echo "======== SEGMENTATION (HARVARD OXFORD) ========"
CORTICAL_ATLAS="/usr/local/fsl/data/atlases/HarvardOxford/HarvardOxford-cort-maxprob-thr25-1mm.nii.gz"
SUBCORTICAL_ATLAS="/usr/local/fsl/data/atlases/HarvardOxford/HarvardOxford-sub-maxprob-thr25-1mm.nii.gz"

CORTICAL_PARCELLATION="${SUBJECT_FOLDER}/Elastic_Cortical.nii.gz"
SUBCORTICAL_PARCELLATION="${SUBJECT_FOLDER}/Elastic_SubCortical.nii.gz"

eval "applywarp --ref=${INM_BRAIN} --in=${CORTICAL_ATLAS} --warp=${WARP_COUT} --out=${CORTICAL_PARCELLATION} --interp=nn"
eval "applywarp --ref=${INM_BRAIN} --in=${SUBCORTICAL_ATLAS} --warp=${WARP_COUT} --out=${SUBCORTICAL_PARCELLATION} --interp=nn"

# Done!
echo "Done!"