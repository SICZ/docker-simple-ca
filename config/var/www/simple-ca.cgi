#!/bin/bash

### DIE ########################################################################

die() {
  echo "HTTP/1.1 500 Internal Server Error"
  echo "Content-Type: text/plain"
  echo
  echo "$*"
  exit 1
}

### BAD_REQUEST ################################################################

badRequest() {
  echo "HTTP/1.1 400 Bad Request"
  echo "Content-Type: text/plain"
  echo
  echo "$*"
  exit 1
}

### NOT_FOUND ##################################################################

notFound() {
  echo "HTTP/1.1 404 Not Found"
  echo "Content-Type: text/plain"
  echo
  echo "404 Not Found"
  exit 1
}

### SIGN #######################################################################

sign() {
  local CRT=$1
  unset DN DNS IP RID
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
      rid)
        RID=${VARVALUE}
        ;;
      *)
        badRequest "Unknown parameter '${PARAM}'"
        ;;
    esac
  done
  unset IFS

  [ -z "${DN}" ] && die "dn=<DN> is mandatory"

  # OpenSSL random file location
  export RANDFILE=./.rnd

  exec 100</etc/ssl/openssl.cnf &&
  flock -x 100 &&
  openssl ca \
    -batch \
    -passin "file:${CA_KEY_PWD_FILE}" \
    -notext \
    -subj "/${DN}" \
    -in <(cat -) \
    -out "${CRT}" \
    -extfile <(
      echo "subjectAltName=@alt_names"
      echo "[ alt_names ]"
      IFS="," # Split string at ','
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
      for ALT_RID in ${RID}; do
        [ -n "${ALT_RID}" ] || continue
        echo "RID.${i}=${ALT_RID}"
        i=$((i+1))
      done
      unset IFS
    )
  flock -u 100
}

### MAIN #######################################################################

# Switch to CA directory
if [ -z "${CA_DIR}" -o ! -d "${CA_DIR}" ]; then
  die "CA dir '${CA_DIR}' not found"
fi
cd "${CA_DIR}"

# Set umask for OpenSSL
umask 0027

# Handle URI
case "${PATH_INFO}" in
  /sign)
    CRT=/tmp/$$.crt
    trap "rm -f ${CRT}" EXIT
    ERR=$(sign "${CRT}" 2>&1) || die "${ERR}"
    OUT="${CRT}"
    ;;
  /ca.crt)
    OUT="${CA_CRT_FILE}"
    ;;
  *)
    notFound
    ;;
esac

# Return certificate
echo "HTTP/1.1 200 OK"
echo "Content-Type: text/plain"
echo
cat "${OUT}"

################################################################################
