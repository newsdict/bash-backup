#!/usr/bin/env bash
# ===================================
# bash-backup
#  Main backup script by bash 4.*
#
# author: yusuke@newsdict.xyz
# LICENSE: MIT License
# github: newsdict/bash-backup.git
# ===================================

# The Set Buildin
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o errexit
set -o pipefail

# Current Paht of script
dir_pattern=/usr/local
if [[ $BASH_SOURCE =~ $dir_pattern ]]; then
  current_path=$(readlink -f $(dirname $BASH_SOURCE)/../share/bash-backup)
else
  current_path=$(readlink -f $(dirname $BASH_SOURCE)/../)
fi

# Include functions
source $current_path/functions.sh

# parse arguments
declare -A options
pasrse_arguments $@

# debug
if [ ! -z "${options[debug]}" ]; then
  set -o xtrace
fi

# version
if [ ! -z "${options[0]}" ] && [ ${options[0]} = "version" ]; then
  version
  exit
fi

# init app
initialize

if [ ! -z "$(get_require_environments)" ];then
  #require env
  source $(get_require_environments)
else
  echo 'Not Found .env[-*] file'
  echo " $ cp $current_path/env-example $HOME/.env and Edit"
  exit
fi

# create temporary directory
create_temporary_directory

if [ $archive = 1 ]; then
  # create archive files from $archive_paths
  archive
fi

if [ $database = 1 ]; then
  # dump from database
  dump_database
fi

# compress archive and dump file
compress

# upload to storage
upload_storage

# clean up temporary files
clean