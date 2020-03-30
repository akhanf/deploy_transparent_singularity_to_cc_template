#!/bin/bash

######################################################################
# modified version of https://github.com/CAIsr/transparent-singularity
# add two args:
#    FULLPATH_TO_CONTAINER_IMAGE
#    SAVE_MODULE_FILE_PATH
######################################################################


#########
#Parameters
#########
if [[ "$#" -ne 2 ]]; then
    echo "usage: run_tranparent_singularity.sh fullpath_to_container_image save_module_file_path"
    exit
fi

FULLPATH_TO_CONTAINER_IMAGE=$1
SAVE_MODULE_FILE_PATH=$2

# get real path
FULLPATH_TO_CONTAINER_IMAGE=$(realpath "${FULLPATH_TO_CONTAINER_IMAGE}")

# get dirname and basename
CONTAINER_IMAGE_PATH=$(dirname "${FULLPATH_TO_CONTAINER_IMAGE}")
CONTAINER_IMAGE=$(basename "${FULLPATH_TO_CONTAINER_IMAGE}")

SCRIPT_PATH=$(dirname $(realpath "$0"))

# define mount points for this system
echo 'warning: it is important to set your system specific mount points in your .bashrc!: e.g. export SINGULARITY_BINDPATH="/opt,/data"'

echo "checking for singularity ..."
qq=`which singularity`
if [[  ${#qq} -lt 1 ]]; then
   echo "This requires singularity on your path. E.g. add module load singularity/2.4.2 to your .bashrc"
   echo "If you are root try again as normal user"
   exit
fi

echo "checking if container image exist"
qq=`ls ${FULLPATH_TO_CONTAINER_IMAGE}`
if  [[  ${#qq} -lt 1 ]]; then
   echo "Can not find ${FULLPATH_TO_CONTAINER_IMAGE}!"
   exit
fi

#mkdir SAVE_MODULE_FILE_PATH
mkdir -p ${SAVE_MODULE_FILE_PATH}

#check which executables exist inside container
singularity exec --pwd ${CONTAINER_IMAGE_PATH} ${FULLPATH_TO_CONTAINER_IMAGE} ${SCRIPT_PATH}/ts_binaryFinder.sh

echo "create singularity executable for each regular executable in commands.txt"
# $@ parses command line options.
while read executable; do \
   FULLPATH_TO_EXECUTABLE=${CONTAINER_IMAGE_PATH}/${executable}
   #echo $executable > ${ABSOLUTE_PATH_TO_EXECUTABLE}; \
   echo "export PWD=\`pwd -P\`" > ${FULLPATH_TO_EXECUTABLE}
   echo "singularity exec --pwd \$PWD ${FULLPATH_TO_CONTAINER_IMAGE} $executable \$@" >> ${FULLPATH_TO_EXECUTABLE}
   chmod a+x ${FULLPATH_TO_EXECUTABLE}
done <${CONTAINER_IMAGE_PATH}/commands.txt

echo "creating activate script that runs deactivate first in case it is already there"
FULLPATH_TO_ACTIVATE_SH=${CONTAINER_IMAGE_PATH}/activate_${CONTAINER_IMAGE}.sh

echo "source deactivate_${CONTAINER_IMAGE}.sh ${CONTAINER_IMAGE_PATH}" > ${FULLPATH_TO_ACTIVATE_SH}
echo -e 'export PWD=`pwd -P`' >> ${FULLPATH_TO_ACTIVATE_SH}
echo -e 'export PATH="$PWD:$PATH"' >> ${FULLPATH_TO_ACTIVATE_SH}
echo -e 'echo "# Container in $PWD" >> ~/.bashrc' >> ${FULLPATH_TO_ACTIVATE_SH}
echo -e 'echo "export PATH="$PWD:\$PATH"" >> ~/.bashrc' >> ${FULLPATH_TO_ACTIVATE_SH}
chmod a+x ${FULLPATH_TO_ACTIVATE_SH}

echo "deactivate script"
FULLPATH_TO_DEACTIVATE_SH=${CONTAINER_IMAGE_PATH}/deactivate_${CONTAINER_IMAGE}.sh
echo  pathToRemove=${CONTAINER_IMAGE_PATH} | cat - ${PATH_OF_SCRIPT}/ts_deactivate_ > temp && mv temp ${FULLPATH_TO_DEACTIVATE_SH}
chmod a+x ${FULLPATH_TO_DEACTIVATE_SH}

echo "create module files in ${SAVE_MODULE_FILE_PATH}"
FULLPATH_TO_MODULE_FILE=${SAVE_MODULE_FILE_PATH}/latest
echo "#%Module####################################################################" > ${FULLPATH_TO_MODULE_FILE}
echo "module-whatis  ${CONTAINER_IMAGE}" >> ${FULLPATH_TO_MODULE_FILE}
echo "prepend-path PATH ${CONTAINER_IMAGE_PATH}" >> ${FULLPATH_TO_MODULE_FILE}

