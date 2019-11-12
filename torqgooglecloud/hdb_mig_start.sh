#!/usr/bin/env bash

olog() { echo "time=$(date -u)|user=${USER}|pwd=${PWD}| $@"; }
elog() { olog "$@" 1>&2; }

# check return, retry it incase it's busy, used for apt-get lock contention
retrycommand() {
  while true; do
    eval "${@}" 
    if [[ $? == 0 ]]; then 
      olog "function returned successfully"
      break;
    fi
    olog "Sleeping for 5 secs..."
    sleep 5
  done
}

Start=$(date -u)
olog "Start ${Start}"

retrycommand apt-get -y update
retrycommand apt-get -y install nfs-common git

# mount filestore
olog "mount filestore1"
sudo mkdir -p /mnt/filestore1
# e.g. sudo mount -r 10.85.151.194:/vol1 /mnt/filestore1
sudo mount -r REPLACE:/vol1 /mnt/filestore1

hdbdir="/mnt/filestore1/hdb"
torquser="REPLACE"
torquserhome="/home/${torquser}"
releasedir="/home/${torquser}/release"
deployfile="${torquserhome}/deploy.sh"

gsutil cp gs://torqdeployment/deploy.sh ${deployfile}
chown ${torquser} ${deployfile}
chmod +x ${deployfile}

olog "${deployfile} exists?" 
if ! test -f "${deployfile}"; then
  elog "required file ${deployfile} does not exist. Exiting..." 
  exit 1
fi

# run torq deploy script
su -c "cd ${torquserhome};${deployfile} -d ${hdbdir}" - ${torquser}

# modify process.csv to include our discovery process
processcsv="${releasedir}/appconfig/process.csv"
olog "${processcsv} exists?" 
if ! test -f "${processcsv}"; then
  elog "required file ${processcsv} does not exist. Exiting..." 
  exit 1
fi

Newprocesscsv=$(cat <<-'EOM'
host,port,proctype,procname,U,localtime,g,T,w,load,startwithall,extras,qcmd
torq-main-vm,6001,discovery,discovery1,${TORQHOME}/appconfig/passwords/accesslist.txt,1,0,,,${KDBCODE}/processes/discovery.q,1,,q
EOM
)

olog "Overwriting ${processcsv} with the following"
echo "${Newprocesscsv}" | tee ${processcsv}

# start the hdbs
sudo -u "${torquser}" -i env releasedir="$releasedir" bash <<'EOF'
cd ${releasedir}
. setenv.sh
# vm format is hdb-instance-group-trlt (extract the random 4 chars at the end)
hdbsuffix="${HOSTNAME##*-}" 
echo "Starting hdb using KDBHDB ${KDBHDB} ..."
nohup q torq.q -load ${KDBHDB} -proctype hdb -procname hdb-scaled-${hdbsuffix} -U ${KDBAPPCONFIG}/passwords/accesslist.txt -localtime -g 1 -T 60 -w 4000 -s 2 -p $((KDBBASEPORT+3)) </dev/null >$KDBLOG/torqhdb.txt 2>&1 &
EOF


End=$(date -u)
olog "End ${End}"
Duration=$(date -u -d @"$(( $(date -u -d "$End" +"%s") - $(date -u -d "$Start" +"%s") ))" +'%-Mm %-Ss')
olog "Duration ${Duration}"

