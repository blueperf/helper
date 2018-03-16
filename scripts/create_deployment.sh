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
    echo "usage: $0 [-c|--cluster] [-i|--imagename] [-y|--yamlfile] [-d|--directory] [-ing|--ingress]"
    echo "  -c      Cluster Name"
    echo "  -i      Image Name"
    echo "  -y      YAML File Name"
    echo "  -d      Directory Name"
    echo "  -ing    (Optional) Set true to Create Ingress Controller"
    exit 1
}

[ -z $1 ] && { usage; }

IMAGENAME=
YAML_FILE=
CLUSTER_NAME=
INGRESS_URL=
INGRESS=false

while true; do
  case "$1" in
    -c | --cluster ) CLUSTER_NAME="$2"; shift 2 ;;
    -i | --imagename ) IMAGENAME="$2"; shift 2 ;;
    -y | --yamlfile ) YAML_FILE="$2"; shift 2 ;;
    -d | --directory ) DIRECTORY="$2"; shift 2 ;;
    -ing | --ingress ) INGRESS="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [[ -z "${CLUSTER_NAME// }" ]]; then
        echo "${yel}No cluster name provided. Will try to get an existing cluster...${end}"
        CLUSTER_NAME=$(bx cs clusters | tail -1 | awk '{print $1}')

        if [[ "$CLUSTER_NAME" == "Name" ]]; then
                echo "No Kubernetes Clusters exist in your account. Please provision one and then run this script again."
                exit 1
        fi
fi
# Getting Cluster Configuration
unset KUBECONFIG
echo "${grn}Getting configuration for cluster ${CLUSTER_NAME}...${end}"
bx cs cluster-config ${CLUSTER_NAME}
eval "$(bx cs cluster-config ${CLUSTER_NAME} | tail -1)"
echo "KUBECONFIG is set to = $KUBECONFIG"

if [[ -z "${KUBECONFIG// }" ]]; then
        echo "KUBECONFIG was not properly set. Exiting"
        exit 1
fi

cd ./${DIRECTORY}
printf "${grn}Generating Temp yaml file for ${YAML_FILE} with ${IMAGENAME}${end}\n"
sed "s#IMAGE_NAME#${IMAGENAME}#g" ${YAML_FILE} > temp.yaml
printf "${grn}Creating Kubernetes Deployment${end}\n"
kubectl create -f ./temp.yaml
printf "${blu}Deleting Temp yaml file${end}\n"
rm temp.yaml

if [ "$INGRESS" = true ] ; then
  eval INGRESS_URL="$(bx cs cluster-get ${CLUSTER_NAME} | grep "Ingress Subdomain" | cut -f 2)"
  printf "${grn}Generating Temp Ingress yaml file for ing.yaml with ${INGRESS_URL}${end}\n"
  sed "s#INGRESS_URL#${INGRESS_URL}#g" ing.yaml > ingtemp.yaml
  printf "${blu}Creating Ingress Controller${end}\n"
  kubectl create -f ./ingtemp.yaml
  printf "${blu}Deleting Temp Ingress yaml file${end}\n"
  rm ingtemp.yaml
fi



