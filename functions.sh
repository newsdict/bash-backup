# ===================================
# bash-backup
#  Functions file
#
# author: yusuke@newsdict.xyz
# LICENSE: MIT License
# github: newsdict/bash-backup
# ===================================

# current date time
now=$(date +%Y%m%d%H%M)
date=$(date +%Y%m%d)

# Requre enviroment file
if [ ! -z "$1" ] && [ -f $current_path/.env-$1 ]; then
  source $current_path/.env-$1
elif [ -f $current_path/.env ]; then
  source $current_path/.env
else
  # cannot use log::error
  echo '[ERROR] not found .env file'
  exit
fi

function upload_storage()
{
  log::info "####"
  log::info "# start to upload storage"
  log::info "####"

  _backup_path="s3://${s3_conf["bucket"]}/${s3_conf["path"]}"
  S3_ACCESS_KEY=${s3_conf["access_key"]}
  S3_SECRET=${s3_conf["secret"]}
  _option="--region ${s3_conf["region"]}"

  aws $_option s3 cp --quiet $compress_name $_backup_path/
  log::info "uploaded: $_backup_path/$(basename $compress_name)"

  for _file in $(aws $_option s3 ls $_backup_path/ | awk '{print $4}' ); do
  	if ! grep $_file <(aws $_option s3 ls $_backup_path/ | awk '{print $4}' |tail -n ${s3_conf["keep"]}) >/dev/null ;then
  		aws $_option s3 rm --quiet $_backup_path/$_file && log::info "deleted file: $_backup_path/$_file"
  	fi
  done

  log::info "####"
  log::info "# uploaded storage"
  log::info "####"
}
function compress()
{
  log::info "####"
  log::info "# start compress"
  log::info "####"

  pushd $working_directory > /dev/null

  _compress_name=$current_path/$temporary_directory/$backup_filename.$date

  if [ "$commpression_type" = "gzip" ]; then

    tar -zcf $_compress_name.tar.gz ./*
    compress_name="$_compress_name.tar.gz"
    log::info "compress: $compress_name"

  elif [ "$commpression_type" = "zip" ]; then

    zip -rq $archive_file.zip ./*
    compress_name="$_compress_name.zip"
    log::info "compress: $compress_name"

  elif [ "$commpression_type" = "bzip2" ]; then

    tar -jcf $archive_file.tar.bz2 ./*
    compress_name="$_compress_name.tar.bz2"
    log::info "compress: $compress_name"

  fi

  popd > /dev/null
  log::info "####"
  log::info "# end compress"
  log::info "####"
}

function dump_database()
{
  log::info "####"
  log::info "# start database dump"
  log::info "####"
  if [ ${database_conf["engine"]} = "mysql" ]; then

    _dump_file=$working_directory/mysql.dump
    echo "[client]
      user = ${database_conf["username"]}
      password = ${database_conf["password"]}
      port = ${database_conf["port"]}
      host = ${database_conf["host"]}" > $current_path/$temporary_directory/my.cnf
    mysqldump \
      --defaults-file=$current_path/$temporary_directory/my.cnf \
      ${database_conf["name"]} > $_dump_file
    rm $current_path/$temporary_directory/my.cnf
    log::info "dump file: $_dump_file"

  fi
  log::info "####"
  log::info "# end database dump"
  log::info "####"
}

function archive()
{
  log::info "####"
  log::info "# start archive"
  log::info "####"
  archive_file=$working_directory/archive

  if [ "$commpression_type" = "gzip" ]; then

    # Suppress `tar: Removing leading `/' from member names`
    declare -a _archive_path
    for ((i = 0; i < ${#archive_paths[@]}; i++)) {
      _archive_path[i]=$(echo ${archive_paths[i]} | sed 's#^/##')
    }
    tar -zcf $archive_file.tar.gz -C / ${_archive_path[@]}
    log::info "archive: $archive_file.tar.gz"

  elif [ "$commpression_type" = "zip" ]; then

    zip -rq $archive_file.zip ${archive_paths[@]}
    log::info "archive: $archive_file.zip"

  elif [ "$commpression_type" = "bzip2" ]; then

    # Suppress `tar: Removing leading `/' from member names`
    declare -a _archive_path
    for ((i = 0; i < ${#archive_paths[@]}; i++)) {
      _archive_path[i]=$(echo ${archive_paths[i]} | sed 's#^/##')
    }
    tar -jcf $archive_file.tar.bz2 -C / ${_archive_path[@]}
    log::info "archive: $archive_file.tar.bz2"

  fi

  log::info "####"
  log::info "# end archive"
  log::info "####"
}

function initialize()
{
  if [ -z "$temporary_directory" ]; then
    # set default temporary directory
    temporary_directory=tmp
  fi
  if [ -z "$log_name" ]; then
    # set default log filename
    log_name=logs/backup.$now.log
  fi
  if [ -z "$backup_filename" ]; then
    # set default backup filename
    backup_filename=backup
  fi
  if [ -z "$display_messages" ]; then
    # set default display_messages
    display_messages=1
  fi
  if [ -z "$archive" ]; then
    archive=0
  fi
  if [ -z "$database" ]; then
    database=0
  fi
  if [ -z "$commpression_type" ] ||
    ([ "$commpression_type" != "gzip" ] &&
    [ "$commpression_type" != "zip" ] &&
    [ "$commpression_type" != "bzip2" ]); then
    log::error "commpression_type is not match"
  fi
  if [ $archive != 1 ] && [ $database != 1 ]; then
    log::error "set archive or database"
  fi

  working_directory=$current_path/$temporary_directory/$backup_filename.$now
  if [ ! -d $working_directory ]; then
    mkdir $working_directory
  fi
}
function clean()
{
  rm -rf $working_directory
  rm $compress_name
}

function log::info(){
  echo "["$(date +"%Y-%m-%d %H:%M:%S")"] "$1 2>&1 >> $current_path/$log_name
  if [ $display_messages -eq 1 ]; then
    echo -e "\e[1;32m["$(date +"%Y-%m-%d %H:%M:%S")"] "$1"\e[0m"
  fi
}
function log::error(){
  echo "["$(date +"%Y-%m-%d %H:%M:%S")"] [ERROR] "$1 2>&1 >> $current_path/$log_name
  if [ $display_messages -eq 1 ]; then
    echo -e "\e[1;31m["$(date +"%Y-%m-%d %H:%M:%S")"] [ERROR] "$1"\e[0m"
  fi
  exit 1
}
