FROM ubuntu:18.04

# Put your executables in DEPLOY_PATH, run_transparent_singularity.sh will look for executables in this folder
ENV DEPLOY_PATH=/opt/project/bin

WORKDIR $DEPLOY_PATH
COPY ./binary .

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH=$DEPLOY_PATH:$PATH


