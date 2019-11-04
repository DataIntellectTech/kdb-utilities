#!/usr/bin/env bash
set -e

# emboldens output, used for important steps
olog() { echo "$@"; }
elog() { olog "$@" 1>&2; }
nextstep() { printf -- "-%.0s" {1..40}; echo; }

usage() {
  cat << EOF
usage: ${0} [-t|--torq <TorQ tag version>] [-f|-fsb <TorQ-Finance-Starter-Pack tag version>] [-h|--help]

TorQ deployment script

OPTIONS
  -t|--torq   <version> - will use tag version, if flag is not used it'll default to most recent
  -f|--fsb    <version> - will use tag version, if flag is not used it'll default to most recent
  -l|--kdblog <path>    - replace the KDBLOG envvar in release/setenv.sh, if flag is not used it will not replace
  -d|--kdbhdb <path>    - replace the KDBHDB envvar in release/setenv.sh, if flag is not used it will not replace
  -w|--kdbwdb <path>    - replace the KDBWDB envvar in release/setenv.sh, if flag is not used it will not replace
  -h|--help   

This script will copy the TorQ[1] and TorQ-Finance-Starter-Pack[2] repos 
into the same directory which is 

It will create:
  ./src directory to hold the two repos
  ./release directory contains two combined repos with .git folder omitted
  ./release.txt detailing what tag versions were used in deployment

[1] https://github.com/AquaQAnalytics/TorQ 
[2] https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack

EOF
  exit 1
}

optfail(){
  elog "$1 requires an argument if used"
  usage
}

OPTS=`getopt -o t:f:l:d:w:h --long torq:,fsb:,kdblog:,kdbhdb:,kdbwdb:,help -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"

while true; do
  case "$1" in
    -t | --torq   ) [[ "$2" = --* ]] && optfail $1; trqver="$2"; shift 2 ;;
    -f | --fsb    ) [[ "$2" = --* ]] && optfail $1; fsbver="$2"; shift 2 ;;
    -l | --kdblog ) [[ "$2" = --* ]] && optfail $1; kdblog="$2"; shift 2 ;;
    -d | --kdbhdb ) [[ "$2" = --* ]] && optfail $1; kdbhdb="$2"; shift 2 ;;
    -w | --kdbwdb ) [[ "$2" = --* ]] && optfail $1; kdbwdb="$2"; shift 2 ;;
    -h | --help   ) usage ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

echo "torq   $trqver"
echo "fsb    $fsbver"
echo "kdblog $kdblog"
echo "kdbhdb $kdbhdb"
echo "kdbwdb $kdbwdb"

#Deployment script
#	- TorQ <Version> (default latest if version it omitted)
#	- TorQ App (FSP for default?)
#		- Tradefeedr deployment (chris)
#	- deployment dir
#	- data dir (log files, hdbs, wdb)


# First version of this script assumes the kx instance has been deployed
# It is to be run after the box has been deployed

basedir=${PWD}

command -v git &>/dev/null || { elog "please install git"; exit 1; }
mkdir -p release src

nextstep
## get TorQ repo
cd src
git clone https://github.com/AquaQAnalytics/TorQ 
cd TorQ
if test -z "${trqver}" ; then
	olog "getting latest tag"
	trqver=$(git describe --tags --abbrev=0)
	olog "latest tag -> ${trqver}"
fi
# git tag -l to list tags in the TorQ directory
git tag -l | grep ${trqver} &>/dev/null || { echo "This given torq version tag does not exist. Please check the repo (src/TorQ) tags with git tag -l"; exit 1; }
#git checkout --quiet tags/${trqver}
nextstep
olog "Copying TorQ ${trqver} to ../release directory"
git archive ${trqver} | tar --overwrite -x -C ${basedir}/release
cd ..

nextstep
## get FSB
git clone https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack
cd TorQ-Finance-Starter-Pack
if test -z "${fsbver}" ; then
	olog "getting latest tag"
	fsbver=$(git describe --tags --abbrev=0)
	olog "latest tag -> ${fsbver}"
fi
git tag -l | grep ${fsbver} &>/dev/null || { echo "The given fsb version tag does not exist. Please check the repo (src/TorQ-Finance-Starter-Pack) tags with git tag -l"; exit 1; }
#git checkout --quiet tags/${fsbver}

nextstep
olog "Copying TorQ-Finance-Starter-Pack ${fsbver} to ../release directory"
git archive ${fsbver} | tar --overwrite -x -C ${basedir}/release
cd $basedir

# Add info to release.txt
echo "TorQ Version = ${trqver}" > release.txt
echo "TorQ-Finance-Starter-Pack Version = ${fsbver}" >> release.txt
echo "Release directory = ${basedir}/release" >> release.txt

# file is required for envvar updates, do a single check and panic if it doesn't exist
# copy it for any sed replaces, it'll be deleted regardless
if ! test -f "release/setenv.sh"; then
  elog "release/setenv.sh does not exist, cannot perform in place envvar updates"
fi

if ! test -z "${kdblog}"; then
  olog "replacing default \$KDBLOG envvar with ${kdblog} in release/setenv.sh"
  sed -i '/^export KDBLOG=/s:=.*$:='"${kdblog}"':' release/setenv.sh
  echo "KDBLOG - ${kdblog}" >> release.txt
fi
if ! test -z "${kdbhdb}"; then
  olog "replacing default \$KDBHDB envvar with ${kdbhdb} in release/setenv.sh"
  sed -i '/^export KDBHDB=/s:=.*$:='"${kdbhdb}"':' release/setenv.sh
  echo "KDBHDB - ${kdbhdb}" >> release.txt
fi
if ! test -z "${kdbwdb}"; then
  olog "replacing default \$KDBWDB envvar with ${kdbwdb} in release/setenv.sh"
  sed -i '/^export KDBWDB=/s:=.*$:='"${kdbwdb}"':' release/setenv.sh
  echo "KDBWDB - ${kdbwdb}" >> release.txt
fi

nextstep
olog "Summary (saved to release.txt)"
cat release.txt

nextstep
olog "Before you run release/start_torq_demo.sh"
olog "Please check and modify the following envvars found in release/setenv.sh"
olog "  .e.g KDBHDB will be your mounted filestore"
echo "KDBLOG"
echo "KDBHDB"
echo "KDBWDB"

