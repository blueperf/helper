Helper script makes it easier to deploy Acmeair to IBM Container Service (Kubernetes).

## Scripts
These are the scrpts that helps creating the Acmeair Microservices
- **IBMCloud_CS.sh** : This script supports these following operations.  Created Apps to use Ingress Controller (note, ingress.yaml file might need to be manually run. e.g. kubectl create -f ingress.yaml)
  - Login
  - Clone Github
  - Create Image
  - Deploy to IBM Container Service
  
- **IBMCloud_CS_ISTIO.sh** : This script supports these following operations.  Created Acmeair Microservices use [ISTIO](https://github.com/istio/istio). Note: Currently, there is a bug that needs workaround to access [backend DB](https://github.com/istio/istio/issues/1476)
  - Login
  - Clone Github
  - Create Image
  - Deploy to IBM Container Service

- **removeImages.sh** :This script helps deleting the images created in the IBM Container Registry. Optionally, it can delete all containers & images created on the local job execution box on Linux (Please uncomment within the script to enable optional feature)
  - Remove Images

- **IBMCloud_CS_SVC.sh & IBMCloud_CS_SVC_ISTIO.sh** : These scirps are for acmeair microservice specific.  It can eliminate service name from SERVICE_NAME. e.g. If directory name is authservice-java = -s auth -r java 

## Prerequisites
In order to build Java Images, the hosting server must be **Linux**.  Also, [docker](https://www.docker.com/),[git](https://git-scm.com/downloads),  Java & [Maven](https://maven.apache.org/) must be installed

run command **mvn** to verify that maven is properly installed.

Run the following to get the helper scripts
- git clone https://github.ibm.com/ibmperf/helper
  
## Setup
Edit the script (IBMCloud_CS.sh or IBMCloud_CS_ISTIO.sh) to enter these values
- NAMESPACE
  - Namespace created in the IBM Container Registry to save the Docker Images. 
  - Following command will display your current namespaces
    - bx cr namespaces
- (OPTIONAL) If using the docker repository hosted in https://cloud.docker.com INSTEAD of using Container Registry, set the following variables 
  - Set REGISTRY as your docker repository user name
  - Set DOCKER_PASSWORD as your docker repository user password
- CLUSTER_NAME
  - Kubernetes Cluster that you have created (Free cluster will not work for the Acmeair Microservices). 
  - Following command will display your current clusters
    - bx cs clusters
- API_KEY
  - API Key can be generated through [IBM Cloud Dashboard](https://console.bluemix.net/dashboard). Go to "Manage" > "Security" > "IBM Cloud API Keys" to generate one.
- SPACE
  - Default is **dev**.  Please change it to the space which you are going to use.
  - To find out your spaces, login [IBM Cloud Dashboard](https://console.bluemix.net/dashboard). On the top, click your account name
    - (e.g. John Doe's Account | US South : jdoe_org : dev)
  - Select the correct account, region, org, then pick the space name
- REGION
  - Default is **ng** whcih means it us US South - Dallas, TX.  Please change it to the Region which you are going to use.
  - To find out your regions, login [IBM Cloud Dashboard](https://console.bluemix.net/dashboard). On the top, click your account name
    - (e.g. John Doe's Account | US South : jdoe_org : dev)
  - Select the correct account, then pick the region name. [Find the corresponding Region Prefix to be used in the script](https://www.ibm.com/cloud-computing/bluemix/data-centers)
    - US South : ng
    - United Kingdom : eu-gb
    - Sydney, Australia : au-syd
    - Frankfurt, Germany : eu-de
- GIT_PERSONAL_ACCESS_TOKEN
  - Go to [IBM GHE Profile page](https://github.ibm.com/settings/profile), then generate "Personal Access Token".

Mongo DB connection information variables need to be set.  Please create a Mongo DB using [Compose site](https://app.compose.io), then create user/password for the database.  If using the same Database, set **DB=your DB name**.  If you are using separate DB for each services, please create individual DBs (acmeair_bookingdb, acmeair_customerdb, acmeair_flightdb)
- HOST
- PORT
- USER
- PASSWORD

Default value for DB is "SEPARATE".  If needs to use the same DB, change the following DB name to specific
- DB=SEPARATE

## Downloading, Building, and Deploying
Running ./IBMCloud_CS.sh or ./IBMCloud_CS_ISTIO.sh will give you brief command options
- To Install the Prereq CLIs, run the following command
  - ./IBMCloud_CS.sh -p
  
- To login IBM Cloud CLI, run the following command
  - ./IBMCloud_CS.sh -l
  
- To Download each services, run the following command (Polyglot Scenario)
  - ./IBMCloud_CS.sh -c -s authservice -r go -b polyglot
    - (Authentication Service written in GO)
  - ./IBMCloud_CS.sh -c -s bookingservice -r java -b polyglot 
    - (Booking Service written in Java : polyglot branch code needs to be used)
  - ./IBMCloud_CS.sh -c -s customerservice -r node -b polyglot 
    - (Customer Service written in Node.js)
  - ./IBMCloud_CS.sh -c -s flightservice -r springboot -b polyglot 
    - (Flight Service written in Springboot : IBM Liberty Profile is used to run the Springboot)
    
- Creating the images : Note: If you are using free Container Registry, it might reach maximum allowed **storage** and **pull traffic**. Please check with the command **bx cr quota**.  If the storage is reached to maximum, please delete "Authentication service" image (bx cr image-rm registry.ng.bluemix.net/moss_perf/auth-go) **AFTER** deploying to the Kubernetes.  These images are used to recover failures & auto Scaling.  If you see "ImagePulledOff" in kubectl get pods, that means either the image does not exist, or it reached to maximum pull traffic for the month.
  - ./IBMCloud_CS.sh -i -s authservice -r go
  - ./IBMCloud_CS.sh -i -s bookingservice -r java
  - ./IBMCloud_CS.sh -i -s customerservice -r node
  - ./IBMCloud_CS.sh -i -s flightservice -r springboot
    
- Deploying to IBM Container Service (Kubernetes)
  - ./IBMCloud_CS.sh -d -s authservice -r go
  - ./IBMCloud_CS.sh -d -s bookingservice -r java
  - ./IBMCloud_CS.sh -d -s customerservice -r node
  - ./IBMCloud_CS.sh -d -s flightservice -r springboot

## Java Microservices Scenario ##
- To Download each services, run the following command
  - ./IBMCloud_CS.sh -c -s authservice -r java -b polyglot 
  - ./IBMCloud_CS.sh -c -s bookingservice -r java -b polyglot 
  - ./IBMCloud_CS.sh -c -s customerservice -r java -b polyglot 
  - ./IBMCloud_CS.sh -c -s flightservice -r java -b polyglot 

- To Create images, run the following command
  - ./IBMCloud_CS.sh -i -s authservice -r java
  - ./IBMCloud_CS.sh -i -s bookingservice -r java 
  - ./IBMCloud_CS.sh -i -s customerservice -r java
  - ./IBMCloud_CS.sh -i -s flightservice -r java

- To Deploy images, run the following command
  - ./IBMCloud_CS.sh -d -s authservice -r java
  - ./IBMCloud_CS.sh -d -s bookingservice -r java 
  - ./IBMCloud_CS.sh -d -s customerservice -r java
  - ./IBMCloud_CS.sh -d -s flightservice -r java

## Post Operation ##
Verify that all deployments are running
- kubectl get deploy

Get the Application URL:
- kubectl get ingress
  - If used IBMCloud_CS.sh, use the hostname listed under "HOSTS" for the "NAME" **acme**
  - If used IBMCloud_CS_ISTIO.sh, use the IP address listed under "ADDERSS" for the "NAME" **acme-istio**
  
To populate the DB, run these commands:
- http://**URL/SERVICE_NAME**/loader/load
  - http://169.60.16.42/booking/loader/load
  - http://169.60.16.42/customer/loader/load
  - http://169.60.16.42/flight/loader/load
  
 ## Stressing with jmeter
- Install Oracle JDK (IBM JDK has performane issue with jMeter)
- Install [jMeter](http://jmeter.apache.org/)
- Download [json-simple](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/json-simple/json-simple-1.1.1.jar) & put into JMETER_HOME/lib/ext
- Download [acmeair-jmeter-2.0.0-SNAPSHOT.jar](acmeair-jmeter-2.0.0-SNAPSHOT.jar) into JMETER_HOME/lib/ext
- Download contents of [this directory](https://github.ibm.com/ibmperf/acmeair-driver/tree/master/acmeair-jmeter/scripts)
 
- Warmup with the following command:
  - jmeter -n -t AcmeAir-microservices.jmx -DusePureIDs=true -JHOST=HOSTNAME/IP_ADDRESS -JPORT=80 -j acmeair.log -JTHREAD=1 -JUSER=999 -JDURATION=60 -JRAMP=0
 
- Run the following.  Change the options for the best performance
  - -JTHREAD : Simulated Number of Users
 
  - jmeter -n -t AcmeAir-microservices.jmx -DusePureIDs=true -JHOST=HOSTNAME/IP_ADDRESS -JPORT=80 -j acmeair.log -JTHREAD=20 -JUSER=999 -JDURATION=600 -JRAMP=120
 
## Monolithic App
 - Use IBMCloud_mono_CS.sh to install acmeair nodejs version
 - ./IBMCloud_CS.sh -c -s acmeair -r nodejs
 - ./IBMCloud_CS.sh -i -s acmeair -r nodejs
 - ./IBMCloud_CS.sh -d -s acmeair -r nodejs
 - Manually run the following command to create ingress
   - Replace INGRESS_URL with your Ingress URL in acmeair-nodejs/ing.yaml
   - kubectl create -f acmeair-nodejs/ing.yaml
 