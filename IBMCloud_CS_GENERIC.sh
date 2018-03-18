#!/bin/bash
set -e
##################################################
####ENTER THESE VARIABLES TO USE THIS SCRIPT####
##################################################
#API_KEY is needed for bx commands for authentication
API_KEY=
CLUSTER_NAME=
#Default Dallas Region, dev space
REGION=ng
SPACE=dev

#Default IBM Cloud Registry at registry.${REGION}.bluemix.net. If docker repository hosted in https://cloud.docker.com is used, change the registry name to your docker username, then add docker password
REGISTRY=registry.${REGION}.bluemix.net
NAMESPACE=
DOCKER_PASSWORD=
IMAGE_TAG=latest
#IMAGE_TAG=test

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
    echo "usage:"
    echo "${cyn}To Install CLI and plugins${end}" $0 " [-p|--prep]"
    echo "e.g.${grn} $0 -p${end}"
    echo "${cyn}To Login IBM Cloud and Container Service${end}" $0 " [-l|--login]"
    echo "e.g.${grn} $0 -l${end}"
    echo "NOTE:  Use Repository Name as REPOSITORY_NAME. e.g. acmeair-monolithic-java = -r acmeair-monolithic-java"
    echo "${cyn}To Clone git repository from GHE${end}" $0 " [-c|--clone] [-r|--repository] <REPOSITORY_NAME> (OPTIPONAL [-b|--branch] <BRANCH_NAME>)"
    echo "e.g.${grn} $0 -c -r acmeair-monolithic-java -b polyglot${end}"
    echo "${cyn}To Create an Image in Container Registry${end}" $0 " [-i|--image] [-r|--repository] <REPOSITORY_NAME> (OPTIPONAL [-f|--dockerfile] <DOCKER_FILE_NAME>)"
    echo "e.g.${grn} $0 -i -r acmeair-monolithic-java -f Dockerfile${end}"
    echo "${cyn}To Deploy an Image in Container Service${end}" $0 " [-d|--deploy] [-r|--repository] <REPOSITORY_NAME>"
    echo "e.g.${grn} $0 -d -r acmeair-monolithic-java ${end}"
    echo "Details of all options:"
    #echo "  -a      Perform all below operations"
    echo "  -p      Install CLI and plugins"
    echo "  -l      Login IBM Cloud and Container Service"
    echo "  -c      Clone git repository from GHE : Use along with -r and -b(optional) options"
    echo "  -b      (Optional) github branch name - Default : master"
    echo "  -i      Create an Image : Use along with -r and -f(optional) options"
    echo "  -d      Deploy an Image : Use along with -r option"
    echo "  -r      Repository Name (e.g. acmeair-monolithic-java, acmeair-monolithic-nodejs)"
    echo "  -f      (Optional) Docker File Name - Default : Dockerfile_CS"
    exit 1
}

[ -z $1 ] && { usage; }

printf "Region : ${cyn}$REGION${end}\n"
printf "Cluster : ${cyn}$CLUSTER_NAME${end}\n"
printf "Namespace : ${cyn}$NAMESPACE${end}\n"

BRANCH=master
DOCKERFILE=Dockerfile_CS
LOGIN=false
CLI=false
CLONE=false
IMAGE=false
DEPLOY=false
INGRESS=true
REPOSITORY_NAME=

while true; do
  case "$1" in
    #-a | --all ) LOGIN=true;CLI=true;IMAGE=true;DEPLOY=true; shift;;
    -p | --prep ) CLI=true; shift;;
    -l | --login ) LOGIN=true; shift;;
    -i | --image ) IMAGE=true; shift ;;
    -d | --deploy ) DEPLOY=true; shift;;
    -c | --clone ) CLONE=true; shift;;
    -b | --branch ) BRANCH="$2"; shift 2 ;;
    -r | --repository ) REPOSITORY_NAME="$2"; shift 2 ;;
    -f | --dockerfile ) DOCKERFILE="$2"; shift 2 ;;
       -- ) shift; break ;;
    * ) break ;;
  esac
done

YAML_FILE=${REPOSITORY_NAME}.yaml
DIRECTORY=${REPOSITORY_NAME}
if [[  ${REGISTRY} == *"bluemix.net"*  ]] ; then
  IMAGE_NAME=${REGISTRY}/${NAMESPACE}/${REPOSITORY_NAME}:${IMAGE_TAG}
else
  IMAGE_NAME=${REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}
  docker login -u ${REGISTRY} -p ${DOCKER_PASSWORD}
fi

if [ "$CLI" = true ] ; then
  printf "${grn}Running install_cli.sh${end}\n"
  ./scripts/install_cli.sh 
fi
if [[ "$LOGIN" = true && -n "${API_KEY// }" ]] ; then
  printf "${grn}Running login_ibmcloud.sh with ${API_KEY} ${SPACE} ${REGION}${end}\n"
  ./scripts/login_ibmcloud.sh -a ${API_KEY} -s ${SPACE} -r ${REGION}
fi

if [[ "$CLONE" = true ]] ; then
  printf "${cyn}Cloning ${BRANCH} branch for ${DIRECTORY}${end}\n"
  git clone https://github.com/blueperf/${DIRECTORY} -b ${BRANCH} --single-branch
fi

if [[ "$IMAGE" = true && -n "${REPOSITORY_NAME// }" ]] ; then
  printf "${cyn}Running create_image.sh with ${IMAGE_NAME} in ${DIRECTORY} with ${DOCKERFILE}${end}\n"
  ./scripts/create_image.sh -i ${IMAGE_NAME} -d ${DIRECTORY} -f ${DOCKERFILE}
fi

if [[ "$DEPLOY" = true && -n "${REPOSITORY_NAME// }" && -n "${CLUSTER_NAME// }" ]] ; then
  printf "${cyn}Running create_deployment.sh with ${CLUSTER_NAME} ${IMAGE_NAME} ${YAML_FILE} in ${DIRECTORY} with Ingress is ${INGRESS}${end}\n"
  ./scripts/create_deployment.sh -c ${CLUSTER_NAME} -i ${IMAGE_NAME} -y ${YAML_FILE} -d ${DIRECTORY} -ing ${INGRESS}
fi
