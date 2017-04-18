#!/bin/bash

set -e

die() {
  echo "HTTP/1.1 500 Internal Server Error"
  echo "Content-Type: text/plain"
  echo
  echo "$*"
  exit 1
}

badRequest() {
  echo "HTTP/1.1 400 Bad Request"
  echo "Content-Type: text/plain"
  echo
  echo "$*"
  exit 1
}

notFound() {
  echo "HTTP/1.1 404 Not Found"
  echo "Content-Type: text/plain"
  echo
  echo "404 Not Found"
  exit 1
}

if [ ! -d "${SIMPLE_CA_DIR}" ]; then
  die "CA not found"
fi
cd "${CA_DIR}"
export RANDFILE=${SIMPLE_CA_DIR}/.rnd

sign() {
  local CRT=$1
  unset DN DNS IP OID
  IFS="&" # Split strings at '&'
  for PARAM in ${QUERY_STRING}; do
    VARNAME="${PARAM%%=*}"
    VARVALUE="${PARAM#*=}"
    case "${VARNAME}" in
      dn)
        DN=${VARVALUE}
        ;;
      dns)
        DNS=${VARVALUE}
        ;;
      ip)
        IP=${VARVALUE}
        ;;
      oid)
        OID=${VARVALUE}
        ;;
      *)
        badRequest "Unknown parameter '${PARAM}'"
        ;;
    esac
  done
  unset IFS

  [ -z "${DN}" ] && die "dn=<DN> is mandatory"

  exec 100</etc/ssl/openssl.cnf &&
  flock 100 &&
  openssl ca \
    -batch \
    -passin "file:${CA_KEY_PWD_FILE}" \
    -notext \
    -subj "/${DN}" \
    -in <(cat -) \
    -out "${CRT}" \
    -extfile <(
      echo "subjectAltName=critical,@alt_names"
      echo "[ alt_names ]"
      IFS="," # Split strings at ','
      i=1
      for ALT_DNS in ${DNS}; do
        [ -n "${ALT_DNS}" ] || continue
        echo "DNS.${i}=${ALT_DNS}"
        i=$((i+1))
      done
      i=1
      for ALT_IP in ${IP}; do
        [ -n "${ALT_IP}" ] || continue
        echo "IP.${i}=${ALT_IP}"
        i=$((i+1))
      done
      i=1
      for ALT_OID in ${OIS}; do
        [ -n "${ALT_OID}" ] || continue
        echo "RID.${i}=${ALT_OID}"
        i=$((i+1))
      done
      unset IFS
    )
}

case "${PATH_INFO}" in
  /sign)
    CRT=/tmp/crt-$$.pem
    trap "rm -f ${CRT}" EXIT
    ERR=$(sign "${CRT}" 2>&1) || die "${ERR}"
    OUT="${CRT}"
    ;;
  /ca.pem)
    OUT="${CA_CRT}"
    ;;
  *)
    notFound
    ;;
esac

echo "HTTP/1.1 200 OK"
echo "Content-Type: text/plain"
echo
cat "${OUT}"
