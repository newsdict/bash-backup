# ===================================
# bash-backup
#  Functions file
#
# author: yusuke@newsdict.xyz
# github: newsdict/bash-scripts.git
# ===================================

# current date time
now=$(date +%Y%m%d%H%M)
date=$(date +%Y%m%d)

# Requre enviroment file
if [ ! -z "$1" ] && [ -f $current_path/.env-$1 ]; then
  source $current_path/.env-$1
else
  source $current_path/.env
fi

function upload_storage()
{
  _backup_path="s3://${s3_conf["bucket"]}/${s3_conf["path"]}/"
  S3_ACCESS_KEY=${s3_conf["access_key"]}
  S3_SECRET=${s3_conf["secret"]}
  
  aws s3 ls

#  echo "[$(date)] awsのストレージにへバックアップファイル（圧縮済）ファイルの転送を開始します..."
#  echo "aws s3 cp ./html_mysql_backup.$date.tar.gz s3://kamakura-net-backup/$target/ > /dev/null"
#  aws s3 cp ./html_mysql_backup.$date.tar.gz s3://kamakura-net-backup/$target/ > /dev/null && echo "[$(date)] awsのストレージにへバックアップファイル（圧ファイルの転送が完了しました"
#
#  if [ "$2" != "--no-remove" ]; then
#  	echo "[$(date)] 作業用ファイルの削除を開始します"
#  	echo "rm -rf ./backup_$date"
#  	rm -rf ./backup_$date && echo "[$(date)] 作業用ファイルの削除を完了しました"
#  	echo "rm -f html_mysql_backup.$date.tar.gz"
#  	rm -f html_mysql_backup.$date.tar.gz && echo "[$(date)] アップロード済みの圧縮ファイルを削除しました。"
#  fi
#
#  echo "[$(date)] 古いファイルを削除します。バックアップは$keep_backup個分残されます"
#  for file in $(aws s3 ls $backup_path | awk '{print $4}' ); do
#  	if ! grep $file <(aws s3 ls $backup_path | awk '{print $4}' |tail -n $keep_backup) >/dev/null ;then
#  		aws s3 rm s3://$backup_path$file && echo "[$(date)] $fileをawsのストレージから削除しました"
#  	fi
#  done
#  popd > /dev/null
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

function log::info(){
  echo "["$(date +"%Y-%m-%d %H:%M:%S")"] "$1 2>&1 >> $current_path/$log_name
  if [ $display_messages -eq 1 ]; then
    echo "["$(date +"%Y-%m-%d %H:%M:%S")"] "$1
  fi
}
function log::error(){
  echo "["$(date +"%Y-%m-%d %H:%M:%S")"] [ERROR] "$1 2>&1 >> $current_path/$log_name
  if [ $display_messages -eq 1 ]; then
    echo "["$(date +"%Y-%m-%d %H:%M:%S")"] [ERROR] "$1
  fi
  exit 1
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
  if [ -z "$commpression_type" ] ||
    ([ "$commpression_type" != "gzip" ] &&
    [ "$commpression_type" != "zip" ] &&
    [ "$commpression_type" != "bzip2" ]); then
    log::error "commpression_type is not match"
  fi

  working_directory=$current_path/$temporary_directory/$backup_filename.$now
  if [ ! -d $working_directory ]; then
    mkdir $working_directory
  fi
}
function clean()
{
  rm -rf $working_directory
}