#!/bin/sh

#########
# steps:
#   singularity pull from docker hub
#   run_transparent_singularity.sh
#########

#########
#Parameters
#########
if [[ "$#" -ne 6 ]]; then
    echo "usage: deploy_dockerhub_image_to_transparent_singularity_on_remote.sh singularity_version deploy_modules_path deploy_containers_path container_name tag dockerhub_image_link" 
    exit
fi

SINGULARITY_VERSION=$1
DEPLOY_MODULES_PATH=$2
DEPLOY_CONTAINERS_PATH=$3
#use REPO_NAME as CONTAINER_NAME
CONTAINER_NAME=$4
TAG=$5
DOCKERHUB_IMAGE_LINK=$6

DEPLOY_CONTAINER_TAG_PATH=${DEPLOY_CONTAINERS_PATH}/${CONTAINER_NAME}/${TAG}
mkdir -p ${DEPLOY_CONTAINER_TAG_PATH}

# singularity pull from docker hub
FULLPATH_TO_SIF=${DEPLOY_CONTAINER_TAG_PATH}/${CONTAINER_NAME}_${TAG}.sif
module load singularity/${SINGULARITY_VERSION}
singularity pull -F ${FULLPATH_TO_SIF} ${DOCKERHUB_IMAGE_LINK}


#transparent singularity
chmod u+x ${DEPLOY_CONTAINERS_PATH}/.deploy_scripts/* 
bash ~/.deploy_scripts/run_transparent_singularity.sh ${FULLPATH_TO_SIF} ${DEPLOY_MODULES_PATH}/${CONTAINER_NAME}

# create a soft link ${CONTAINER_NAME} in ${DEPLOY_CONTAINER_TAG_PATH}
# purpose:
#    'moudle load ${CONTAINER_NAME}/latest'
#    '${CONTAINER_NAME} arg1 arg2' will run Singularity %runscript section
ln -s ${FULLPATH_TO_SIF} ${DEPLOY_CONTAINER_TAG_PATH}/${CONTAINER_NAME}

# add MODULEPATH to ~/.bashrc
if grep -xq "export MODULEPATH=${DEPLOY_MODULES_PATH}:\$MODULEPATH" ~/.bashrc #return 0 if exist
then
    echo "MODULEPATH is in ~/.bashrc"
else
    echo "export MODULEPATH=${DEPLOY_MODULES_PATH}:\$MODULEPATH" >> ~/.bashrc
fi

exit 0
