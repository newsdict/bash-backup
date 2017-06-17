#!/usr/bin/env bash
# ===================================
# bash-backup
#  Main backup script by bash 4.*
#
# version: 0.1.2
# author: yusuke@newsdict.xyz
# LICENSE: MIT License
# github: newsdict/bash-backup.git
# ===================================

# The Set Buildin
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o errexit
set -o pipefail

# Current Paht of script
current_path=$(dirname $(pwd)/$(dirname $BASH_SOURCE))

# Include functions
source $current_path/functions.sh

# init app
initialize

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