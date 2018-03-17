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
    echo "${cyn}To Clone git repository${end}" $0 " [-c|--clone]"
    echo "e.g.${grn} $0 -c${end}"
    echo "${cyn}To Deploy Containers to the Container Service${end}" $0 " [-d|--deploy]"
    echo "e.g.${grn} $0 -d${end}"
    echo "${cyn}To Populate DB${end}" $0 " [-db|--loaddb]"
    echo "e.g.${grn} $0 -db${end}"
    echo "${cyn}To Undeploy Containers from the Container Service${end}" $0 " [-u|--undeploy]"
    echo "e.g.${grn} $0 -u${end}"
    echo "${cyn}To Login, Clone, Deploy and Populate DB NOTE:It will pause 2 minutes before DB polulation. If DB is not populated, run -db separately${end}" $0 " [-a|--all]"
    echo "e.g.${grn} $0 -a${end}"
    echo "Details of all options:"
    echo "  -a      Run below -l, -c, -d and -db commands"
    echo "  -p      Install CLI and plugins"
    echo "  -l      Login IBM Cloud and Container Service"
    echo "  -c      Clone git repositories"
    echo "  -d      Deploy Containers"
    echo "  -db     Load DB"
    echo "  -u      Undeploy Containers"
    exit 1
}

[ -z $1 ] && { usage; }

printf "Region : ${cyn}$REGION${end}\n"
printf "Cluster : ${cyn}$CLUSTER_NAME${end}\n"
printf "Namespace : ${cyn}$NAMESPACE${end}\n"

BRANCH=master
LOGIN=false
CLI=false
CLONE=false
DEPLOY=false
UNDEPLOY=false
INGRESS=false
DB=false
PAUSE=false

while true; do
  case "$1" in
    -a | --all ) LOGIN=true;CLONE=true;DEPLOY=true;DB=true;PAUSE=true; shift;;
    -p | --prep ) CLI=true; shift;;
    -l | --login ) LOGIN=true; shift;;
    -d | --deploy ) DEPLOY=true; shift;;
    -db | --loaddb ) DB=true; shift;;
    -u | --undeploy ) UNDEPLOY=true; shift;;
    -c | --clone ) CLONE=true; shift;;
    -pause | --pause ) PAUSE=true; shift;;
       -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ "$CLI" = true ] ; then
  printf "${grn}Running install_cli.sh${end}\n"
  ./scripts/install_cli.sh 
fi
if [[ "$LOGIN" = true && -n "${API_KEY// }" ]] ; then
  printf "${grn}Running login_IBM Cloud.sh with ${API_KEY} ${SPACE} ${REGION}${end}\n"
  ./scripts/login_ibmcloud.sh -a ${API_KEY} -c ${CLUSTER_NAME} -s ${SPACE} -r ${REGION}
fi

declare -a arr=("acmeair-authservice-java" "acmeair-bookingservice-java" "acmeair-customerservice-java" "acmeair-flightservice-java")
#declare -a arr=("acmeair-bookingservice-java")
if [[ "$CLONE" = true ]] ; then
  printf "${cyn}Cloning Acmair Homogeneous Java Microservice${end}\n"
  for i in "${arr[@]}"
  do
    git clone https://github.com/blueperf/${i}
  done
fi

if [[ "$DEPLOY" = true ]] ; then
  for i in "${arr[@]}"
  do
    printf "${cyn}Creating Image ${i} in ${REGISTRY}${end}\n"
    YAML_FILE=${i}.yaml
    DIRECTORY=${i}
    if [[  ${REGISTRY} == *"bluemix.net"*  ]] ; then
      IMAGE_NAME=${REGISTRY}/${NAMESPACE}/${i}:${IMAGE_TAG}
    else
      IMAGE_NAME=${REGISTRY}/${i}:${IMAGE_TAG}
      docker login -u ${REGISTRY} -p ${DOCKER_PASSWORD}
    fi
    echo ${IMAGE_NAME}
    INGRESS=false
    if [[ ${i} = *"auth"* ]] ; then
      printf "${grn}Also generating Ingress${end}\n"
      INGRESS=true
    fi
    ./scripts/create_image.sh -i ${IMAGE_NAME} -d ${i} -f "Dockerfile"
    ./scripts/create_deployment.sh -c ${CLUSTER_NAME} -i ${IMAGE_NAME} -d ${i}/manifests-demo -y deploy-${i}.yaml -ing ${INGRESS}
  done
fi

if [[ "$PAUSE" = true ]] ; then
  printf "${grn}Pausing 2 minutes for Pods to be created & Liberty Server to startup${end}\n"
  sleep 120
  kubectl get deploy | grep acmeair
fi

if [[ "$DB" = true ]] ; then
  eval INGRESS_URL="$(bx cs cluster-get ${CLUSTER_NAME} | grep "Ingress Subdomain" | cut -f 2)"
  curl http://${INGRESS_URL}/booking/loader/load || true
  printf "\n"
  curl http://${INGRESS_URL}/flight/loader/load || true
  printf "\n"
  curl http://${INGRESS_URL}/customer/loader/load?numCustomers=10000 || true
  printf "\n"
  printf "${grn}Database Loaded${end}\n"
fi

if [[ "$UNDEPLOY" = true ]] ; then
  for i in "${arr[@]}"
  do
    if [[ ${i} = *"auth"* ]] ; then
      printf "${grn}Deleting Ingress${end}\n"
      kubectl delete -f ${i}/manifests-demo/ing.yaml || true
    fi
    kubectl delete -f ${i}/manifests-demo/deploy-${i}.yaml || true
  done
fi
