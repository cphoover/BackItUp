#/bin/bash

CONFIG_PATH="$1"

# define colors
C_DEFAULT="\033[m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"

function log(){
     msg="BACKUP AGENT --- $(date +%s) --- LOG --- %s$1%s"; 
     $SILENT || echo -e $(printf "$msg" ${C_GREEN} ${C_DEFAULT});  
     $LOGGING && logger $(printf "$msg");
}

function error(){
     msg="BACKUP AGENT --- $(date +%s) --- ERROR --- %s$1%s"; 
     $SILENT || echo -e $(printf "$msg" ${C_RED} ${C_DEFAULT});  
     $LOGGING && logger $(printf "$msg");
}

function info(){
     msg="BACKUP AGENT --- $(date +%s) --- INFO --- %s$1%s"; 
     $SILENT || echo -e $(printf "$msg" ${C_YELLOW} ${C_DEFAULT});  
     $LOGGING && logger $(printf "$msg");
}

if [ -z "$CONFIG_PATH" ]; then
    error "No config file specified exiting with error code: 1";
    echo "Usage:";
    echo -e "\tbackup.sh path/to/config.sh";
    exit 1;
fi

CONFIG_FILE="$(basename $CONFIG_PATH)"
CONFIG_DIR="$(dirname $CONFIG_PATH)"

if [ -n $CONFIG_DIR ]; then
    cd $CONFIG_DIR
fi

source $CONFIG_PATH

log "Log: backup tool starting... ";
log "CONFIGURATION:"

info "REMOTE_USER: ${REMOTE_USER}"
info "REMOTE_HOST: ${REMOTE_HOST}"
info "REMOTE_LOCATION: ${REMOTE_LOCATION}"
info "DESTINATION: ${DESTINATION}"
info "BACKUP_DIR: ${BACKUP_DIR}"

log "Checking to see if backup expiry is set";
# IF BACKUP EXPIRY IS SET REMOVE EXPIRED LOCAL BACKUPS
if [[ $BACKUP_EXPIRY ]]; then
    log "Backup expiry is enabled searching for expired files";
    OLDFILES=$(find $BACKUP_DIR/* -mtime +${BACKUP_EXPIRY})
    if [[ $OLDFILES ]]; then
        info "Removing backups older than ${BACKUP_EXPIRY}"
        echo "$OLDFILES" | while read line
        do
            info "Log: removing $line";
            rm $line || { error "Could not remove file $line"; exit 1; }
        done
    fi
fi


## RSYNC PROD WEBROOT TO LOCAL
log "Synchronization using Rsync over ssh";
info "Synchronizing ${REMOTE_HOST}:${REMOTE_LOCATION}";
info "With local: ${DESTINATION}"

rsync --rsync-path="sudo rsync" -avz -e ssh $REMOTE_USER@$REMOTE_HOST:$REMOTE_LOCATION $DESTINATION; RSYNC_EXIT=$?
if [[ $RSYNC_EXIT != 0 ]] ; then
    error "Uh Oh :( Rsync has exited with code: ${RSYNC_EXIT}"
    error "Here is the bad command: rsync --rsync-path=\"sudo rsync\" -avz -e ssh $REMOTE_USER@$REMOTE_HOST:$REMOTE_LOCATION $DESTINATION;"
    exit $RSYNC_EXIT
fi


echo -e "\n"
## CREATE TARBALL
log "Archiving current snapshot";
info "Creating tarball archive of directory $(basename ${DESTINATION%/})"

DATE=$(date +%Y_%m_%d_%H-%M)
NEW_FILE=$(basename ${DESTINATION%/}).${DATE}.tar.gz

LOCAL_DIR=$(dirname "${DESTINATION%/}")
LOCAL_BASE=$(basename "${DESTINATION%/}")

cd $LOCAL_DIR || { error "Could not access ${LOCAL_DIR}"; exit 1; }
tar -czf "$NEW_FILE" "$LOCAL_BASE"; TAR_EXIT=$?
cd -
mv "$LOCAL_DIR/$NEW_FILE" "$BACKUP_DIR/." || { error "Could not move $NEW_FILE to $BACKUP_DIR"; exit 1; }

if [[ $TAR_EXIT != 0 ]] ; then
    error "uh oh :( tar has exited with code: ${TAR_EXIT}"
    error "here is the command: command: tar -czf \"$NEW_FILE\" \"$LOCAL_BASE\"";
    exit $TAR_EXIT
fi

info "created new file: $NEW_FILE";
