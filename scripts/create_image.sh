#!/bin/bash
set -e

function usage {
    echo "usage: $0 [-i|--imagename] [-d|--directory] [-f|--dockerfile]"
    echo "  -i      Image Name"
    echo "  -d      Directory Name"
    echo "  -f      (Optional) Docker File Name - Default : Dockerfile_BlueMix"
    exit 1
}

[ -z $1 ] && { usage; }

IMAGENAME=
DOCKERFILE=Dockerfile_CS
DIRECTORY=

while true; do
  case "$1" in
    -i | --imagename ) IMAGENAME="$2"; shift 2 ;;
    -d | --directory ) DIRECTORY="$2"; shift 2 ;;
    -f | --dockerfile ) DOCKERFILE="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

cd ./${DIRECTORY}

if [[ $IMAGENAME == *"java"* || $IMAGENAME == *"spring"* ]]; then
  mvn clean package
fi
docker build -f ./${DOCKERFILE} -t ${IMAGENAME} .
docker push ${IMAGENAME}
