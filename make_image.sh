#!/bin/bash
#
# Stolen from: https://git.resf.org/sig_altarch/RockyRpi/src/branch/r9/createRocky9_Image.sh

# Exit with error if we don't have an output directory:
OUTDIR=$1

OUTDIR=$1
LOGDIR="logs"
LOGFILE="/create_image`date +"%y%m%d"`.log"
LOGFILE2="create_image`date +"%y%m%d"`.log.2"

if [[ -z "${OUTDIR}" ]]; then
  echo "Need to run this script with a path to output directory.  Like:  ${0}  /path/to/output/"
  exit 1
fi

if [[ -d ${LOGDIR} ]]; then
    echo "$LOGDIR exists..."
else
    mkdir -p "${LOGDIR}"
    touch $LOGDIR/$LOGFILE
fi


if [[ -d ${OUTDIR} ]]; then
    echo "$OUTDIR exists..."
else
    mkdir -p "${OUTDIR}"
fi

mkdir -p "${OUTDIR}"

# Actually create the image.  Our kickstart data should be in the same git repo as this script:
# (This takes a while, especially building on an rpi.  Patience!)
appliance-creator -v -c ./rockypi.ks -n RockyPi \
  --version=`date +"%Y%m%d"`  --release=1 \
  -d --logfile $LOGDIR/LOGFILE \
  --vmem=4096 --vcpu=4 --no-compress -o "${OUTDIR}"
