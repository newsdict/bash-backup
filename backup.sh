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
current_path=$(pwd)/$(dirname $BASH_SOURCE)

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

#require env
source $(get_require_environments)

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