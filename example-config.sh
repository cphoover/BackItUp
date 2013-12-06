########################
## CONFIGURATION HERE ##
########################

#### 
# this user should exist on the remote host with limited privelages
# and should be in the sudoers file with only /usr/bin/rsync available with NOPASSWD
# this user should also not require tty verification Defaults:MyUser !requiretty
# this user's public ssh key should be an authorized key on the target system
# for ONLY the specific client, with the client's host whitelisted.
# password auth over ssh should be disabled for this user for added protection
####

REMOTE_USER="rsyncagent"

REMOTE_HOST="changetomyhost.com"

####
# A special care must be taken when specifying source path. Rsync will operate
# fundamentally different when trainling slash (/) is and isn’t used.
# In other words this
# rsync /home/libor/Documents /mnt/backup
# very different from
# rsync /home/libor/Documents/ /mnt/backup
#
# If you omit traling slash, rsync will create last folder of path before actual 
# content copying. But if you append traling slash to source, rsync will skip
# that folder and copy subfolders and files of that folder directly to target.
# This is generally what we want
# e.g here the contents of vhosts will be copied
# REMOTE_LOCATION="/var/www/vhosts/"
# DESTINATION="./vhosts/"
# whereas here
# REMOTE_LOCATION="/var/www/vhosts"
# DESTINATION="./vhosts"
# rsync will copy the folder itself and you end up with ./vhosts/vhosts
####

REMOTE_LOCATION="/var/www/"
DESTINATION="./www/"
BACKUP_DIR="./backups"

####
# to disable expiry set to false
# format n[smhdw]
####

BACKUP_EXPIRY="3d"

# Prevents logging to stdout
SILENT=false

# Prevents logging to syslog
LOGGING=true

########################
## END CONFIGURATION  ##
########################
