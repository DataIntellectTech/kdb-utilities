# TorQ Google Cloud deployment

Example scripts to run a simple deployment of TorQ on Google Cloud 

## Before script is ran
Replace the filestore mount address with your filestore IP and the torquser variable value with the username that will be used to run the TorQ stack.

```bash
$ grep -n REPLACE hdb_mig_start.sh 
29:sudo mount -r REPLACE:/vol1 /mnt/filestore1
32:torquser="REPLACE"
```


deploy.sh - was created to deploy our TorQ package.

hdb_mig_start.sh - This file requires modification before it is ran.

## deploy.sh
This is a standalone script that will:
1. download [TorQ](https://github.com/AquaQAnalytics/TorQ) (or any version tag)
2. download [TorQ Finance Starter Pack](https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack) (or any version tag)
3. create a release directory with both packages merged

For usage run  
```bash
./deploy.sh -h
```

## hdb_mig_start.sh
1. install git and nfs dependencies
2. mount the filestore
3. run the deploy script
4. start the HDB processes

Assumes discovery process is being ran on the 'torq-main-vm' host

