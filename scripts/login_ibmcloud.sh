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
    echo "usage: $0 [-a|--akipey] [-c|--cluster] [-s|--space] [-r|--region]"
    echo "  -a      API KEY for Bluemix"
    echo "  -c      Cluster Name"
    echo "  -s      (Optional) Space Name - Default : dev"
    echo "  -r      (Optional) Region Name - Default : ng"
    exit 1
}

[ -z $1 ] && { usage; }

API_KEY=
SPACE="dev"
REGION="ng"
CLUSTER_NAME=

while true; do
  case "$1" in
    -a | --apikey ) API_KEY="$2"; shift 2 ;;
    -c | --cluster ) CLUSTER_NAME="$2"; shift 2 ;;
    -s | --space ) SPACE="$2"; shift 2 ;;
    -r | --region ) REGION="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

API="api.${REGION}.bluemix.net"

printf "${grn}API is set to $API${end}\n"

bx plugin update container-service -r Bluemix
bx plugin update container-registry -r Bluemix

# Bluemix Login
printf "${grn}Login into Bluemix${end}\n"
if [[ -z "${API_KEY// }" && -z "${SPACE// }" ]]; then
	echo "${yel}API Key & SPACE NOT provided.${end}"
	bx login -a ${API}

elif [[ -z "${SPACE// }" ]]; then
	echo "${yel}API Key provided but SPACE was NOT provided.${end}"
	export BLUEMIX_API_KEY=${API_KEY}
	bx login -a ${API}

elif [[ -z "${API_KEY// }" ]]; then
	echo "${yel}API Key NOT provided but SPACE was provided.${end}"
	bx login -a ${API} -s ${SPACE}

else
	echo "${yel}API Key and SPACE provided.${end}"
	export BLUEMIX_API_KEY=${API_KEY}
	bx login -a ${API} -s ${SPACE}
fi

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


#printf "\n\n${grn}Getting Account Information...${end}\n"
#ORG=$(cat ~/.bluemix/.cf/config.json | jq .OrganizationFields.Name | sed 's/"//g')
#SPACE=$(cat ~/.bluemix/.cf/config.json | jq .SpaceFields.Name | sed 's/"//g')

# Creating for API KEY
if [[ -z "${API_KEY// }" ]]; then
	printf "\n\n${grn}Creating API KEY...${end}\n"
	API_KEY=$(bx iam api-key-create kubekey | tail -1 | awk '{print $3}')
	echo "${yel}API key 'kubekey' was created.${end}"
	echo "${mag}Please preserve the API key! It cannot be retrieved after it's created.${end}"
	echo "${cyn}Name${end}	kubekey"
	echo "${cyn}API Key${end}	${API_KEY}"
fi

printf "\n\n${grn}Login into Container Service${end}\n\n"
bx cs init

printf "\n\n${grn}Login into Container Registry${end}\n\n"
bx cr login
