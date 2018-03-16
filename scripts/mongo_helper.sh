#!/bin/bash
set -e
# Terminal Colors
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'
coffee=$'\xE2\x98\x95'
coffee3="${coffee} ${coffee} ${coffee}"

function usage {
    echo "usage: $0 [-y|--yaml] [-dir|directory] [-h|--host] [-p|--port] [-u|--user] [-pwd|--password] [-d|--db]"
    echo "  -y      YAML File Name"
    echo "  -dir    Directory Name"
    echo "  -h      Host Name"
    echo "  -p      Port Number"
    echo "  -u      User Name"
    echo "  -pwd      Password"
    echo "  -d      DB Name"
    exit 1
}

[ -z $1 ] && { usage; }

REGISTRY=registry.ng.bluemix.net
YAML_FILE=
DIRECTORY=
HOST_NAME=localhost
PORT_NUMBER=27017
USER_NAME=
PASSWORD=
DB_NAME=acmeair

while true; do
  case "$1" in
    -y | --yaml ) YAML_FILE="$2"; shift 2 ;;
    -dir | --directory ) DIRECTORY="$2"; shift 2 ;;
    -h | --host ) HOST_NAME="$2"; shift 2 ;;
    -p | --port ) PORT_NUMBER="$2"; shift 2 ;;
    -u | --user ) USER_NAME="$2"; shift 2 ;;
    -pwd | --password ) PASSWORD="$2"; shift 2 ;;
    -d | --db ) DB_NAME="$2"; shift 2 ;;
    -ing | --ingress ) INGRESS="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done
cd ./${DIRECTORY}
printf "${grn}Adding DB information for ${YAML_FILE} host=${HOST_NAME}, port=${PORT_NUMBER}, user=${USER_NAME}, password=${PASSWORD}, db=${DB_NAME}${end}\n"
sed "s#MONGO_HOST_VALUE#${HOST_NAME}#g" ${YAML_FILE} > DB_${YAML_FILE}
sed "s#MONGO_PORT_VALUE#${PORT_NUMBER}#g" DB_${YAML_FILE} > DB1_${YAML_FILE}
sed "s#MONGO_USER_VALUE#${USER_NAME}#g" DB1_${YAML_FILE} > DB_${YAML_FILE}
sed "s#MONGO_PASSWORD_VALUE#${PASSWORD}#g" DB_${YAML_FILE} > DB1_${YAML_FILE}
sed "s#MONGO_DBNAME_VALUE#${DB_NAME}#g" DB1_${YAML_FILE} > DB_${YAML_FILE}
rm -Rf DB1_${YAML_FILE}
