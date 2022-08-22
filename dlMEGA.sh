#!/usr/bin/env bash

set -eu

VERSION="1.1.4"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36"
CMD_NAME="${0##*/}"

printerror() {
  errorcodes=(
    "1 - Wrong parameters"
    "2 - Missing dependency: ${2}"
    "3 - Wrong key in ${2}"
    "4 - Canceled transfer: ${2}"
    "5 - Not a MEGA file url: ${2}"
    "6 - File not found: ${2}"
    "7 - Unsupported url: ${2}"
  )
  echo " ${CMD_NAME}: Error ${errorcodes[${1} - 1]}" >&2
}

dload() {
  if echo "$1" | grep -qE '^https://mega\.nz/file/[a-zA-Z0-9]+#[-_a-zA-Z0-9]$'; then
    printerror 7 "$1"
    return
  fi

  param_id=$(echo "$1" | awk -F '[/#]' '{print $5}')
  param_key=$(echo "$1" | awk -F '[/#]' '{print $6}' | tr '_-' '/+')

  if [[ -z $param_key ]]; then
    printerror 5 "$1"
    return
  fi

  key_decimal=$(
    echo "$param_key" | tr '_-' '/+' | base64 -di 2> /dev/null |
      xxd -p | tr -dc 'a-z0-9'
  )
  init_vec="${key_decimal:32:16}0000000000000000"

  key=$(
    printf "%016x" \
      "$((0x${key_decimal:00:16} ^ 0x${key_decimal:32:16}))" \
      "$((0x${key_decimal:16:16} ^ 0x${key_decimal:48:16}))"
  )

  api=$(
    curl -sqLA "$UA" 'https://eu.api.mega.co.nz/cs' \
      -d '[{"a":"g","g":1,"p":"'"$param_id"'"}]'
  )
  dl_url=$(echo "$api" | grep -oE '"g":"[^"]+' | sed 's/^"g":"//')

  if [[ -z $dl_url ]]; then
    printerror 6 "$1"
    return
  fi

  size=$(echo "$api" | grep -oE '"s":[0-9]+' | sed 's/^"s"://')
  sizemb=$((size / 1024 / 1024))

  filename=$(
    echo "$api" | grep -oE '"at":"[^"]+' | sed 's/^"at":"//' |
      tr '_-' '/+' |
      base64 -di 2>/dev/null |
      xxd -p | tr -d '\n' | xxd -p -r |
      openssl enc -d -aes-128-cbc -K "$key" -iv 0 -nopad 2>/dev/null |
      awk -F '"' '{print $4}'
  )

  if [[ -z $filename ]]; then
    printerror 3 "$1"
    return
  fi

  if [[ ${stream:-0} == 1 ]]; then
    mode="Stream"
    filename="/dev/stdout"
    pb="-s"
  else
    mode="File"
  fi

  echo "${mode}: ${filename} Size: ${sizemb}MB" >&2

  if ! {
    curl ${pb:-} -qLA "$UA" "$dl_url" |
      openssl enc -d -aes-128-ctr -K "$key" -iv "$init_vec" >"$filename" 2>/dev/null
  }; then
    printerror 4 "$1"
    echo >&2
  fi
}

main() {
  cat <<A

 dlMEGA, a mega.nz file downloader

 • Version ${VERSION}, free for non-commercial use
 • © 2015 by Herbert Knapp (herbert.knapp at uni-graz.at)

A

  if [[ $# == 0 ]]; then
    cat <<A
 Usage: ${CMD_NAME} [-p --progress-bar] [-s --stream] '<MEGA url>' ['<MEGA url>']

    eg: ${CMD_NAME} --stream 'https://mega.nz/file/<id>#<key>' | mplayer -

        ${CMD_NAME} -p inputfile.txt 'https://mega.nz/file/<id>#<key>'

A
    exit 0
  fi

  for dep in awk base64 curl openssl sed xxd; do
    if ! command -v "$dep" &>/dev/null; then
      printerror 2 "$dep"
      exit 2
    fi
  done

  for param in "${@}"; do
    if [[ $param == '--progress-bar' || $param == '-p' ]]; then
      pb="${pb} --progress-bar"
    elif [[ $param == '--stream' || $param == '-s' ]]; then
      stream=1
    elif [[ -f $param ]]; then
      while read -r line; do
        dload "$line"
      done < <(grep -E '^https://mega\.nz')
    else
      dload "$param"
    fi
  done
}

main "${@}"
exit $?
