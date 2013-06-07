#!/bin/bash



# is it a read only access? use option -r for readonly access
RO=0 

PARSED_OPTIONS=$(getopt -n "$0"  -o r  -- "$@")
if [ $? != 0 ] ; then echo "Options not parsed correctly..." >&2 ; exit 1 ; fi
echo $PARSED_OPTIONS




eval set -- "$PARSED_OPTIONS"

while true ; do
  case "$1" in
    -r) echo "option r"; RO=1 ; shift ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

echo ro=$RO
# password file in $f
f=$1

# Only use aes encryption
if [[ ${f##*.} != 'aes' ]]; then
  # file can be decrypted manyually with this command:
  #   openssl aes-256-cbc -d -salt -in $file.aes
  echo "File needs to have aes extension"
  exit 1
fi

if [[ $RO -eq 0 ]]; then
  # If lockfile exists, check if process editing the file is currently running.
  if [[ -f $f.lock ]]; then
    tempfile=$(mktemp)
    ps aux | grep pwman.sh | grep bash | grep -v $$ |awk '{ printf("user %s is running this pwman command with process id %s:\n", $1,$2);  for(i=12;i<=NF;++i) printf(" %s",$i); print "" }'>$tempfile
    echo "File is locked. Is a current session active?"
    echo "Reminder: with the option -r you can access the file readonly"
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
  cp $f $f.$(date +%Y%m%d-%H:%M:%S).$(id -u -n).back

  # edit with vim and its openssl plugin
  vim $f

  # remove lock file when finished
  rm $f.lock;
else
  # still make a backup copy
  cp $f $f.$(date +%Y%m%d-%H:%M:%S).$(id -u -n).ro
  vim -R $f
fi
