#!/bin/bash

f=$1

# Only use aes encryption
if [[ ${f##*.} != 'aes' ]]; then
  # file can be decrypted manyually with this command:
  #   openssl aes-256-cbc -d -salt -in $file.aes
  echo "File needs to have aes extension"
  exit 1
fi

# If lockfile exists, check if process editing the file is currently running.
if [[ -f $f.lock ]]; then
  tempfile=$(mktemp)
  ps aux | grep pwman.sh | grep bash | grep -v $$ |awk '{ printf("user %s is running this pwman command with process id %s:\n", $1,$2);  for(i=12;i<=NF;++i) printf(" %s",$i); print "" }'>$tempfile
  echo "File is locked. Is a current session active?"
  if [[ -s $tempfile ]]; then
    echo "If the file you want to edit is in the list, contact the user editing it to avoid data loss. Do not edit it!";
  else
    echo "No pwman process found. Maybe this is a stale lock file. If this is the case, you can delete it with the command rm $f.lock and try again";
  fi
  exit 2
fi

# create lock file, holding this process' id. Could be used in a later version
echo $$> $f.lock

# make backup copy
cp $f $f.$(date +%Y%m%d-%H:%M:%S).$(id -u -n)

# edit with vim and its openssl plugin
vim $f

# remove lock file when finished
rm $f.lock
