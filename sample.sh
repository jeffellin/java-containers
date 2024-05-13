#!/bin/bash

# Include the "demo-magic" helpers
source demo-magic.sh

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
TYPE_SPEED=30
export NO_COLOR=1
function comment() {
  cmd=$DEMO_COMMENT_COLOR$1$COLOR_RESET
  echo -en "$cmd"; echo ""
}

clear

comment "# Setup:"
pei 'cd java-app'
pe './mvnw clean package'

comment "# Create the docker image"
pe bat Dockerfile
pe 'docker build -t registry.gcp.ellin.net/library/java-demo .'
pe 'dive registry.gcp.ellin.net/library/java-demo'

comment "Rebuild the image adding a file"
pei './mvnw clean package'
pei bat Dockerfile2
pe 'docker build -f Dockerfile2 -t registry.gcp.ellin.net/library/java-demo .'
pe 'dive registry.gcp.ellin.net/library/java-demo'

comment "Unpack the uber jar"
pei mkdir target/dependency
pei cd target/dependency
pe 'jar -xf ../*.jar'
pei 'ls -la'
pei 'cd ../..'
pei bat Dockerfile3
pe 'docker build -f Dockerfile3 -t registry.gcp.ellin.net/library/java-demo .'
pe 'dive registry.gcp.ellin.net/library/java-demo'

comment "Let's build the Jar with Jib"
pe mvn compile jib:build
comment "Must Pull the Container as Local Docker Daemon was not used"
pe docker pull registry.gcp.ellin.net/library/java-demo
pe dive registry.gcp.ellin.net/library/java-demo

comment "Let's build the Jar with a Cloud Native Buildpack"
pe pack config default-builder  paketobuildpacks/builder-jammy-base
#pei cd java-app
pe pack build registry.gcp.ellin.net/library/java-app 
pe dive registry.gcp.ellin.net/library/java-app

pei cd ../simple-server
comment "another look at CNB"
comment "no Dockerfile"
pei "ls -la"
pe pack build registry.gcp.ellin.net/library/simple-server 
pe dive registry.gcp.ellin.net/library/simple-server

comment "Now a look at Kpack"

pei cd ../kpack
comment "lets cleanup the cluster"
pe kubectl delete builder my-builder
pe kubectl delete clusterstacks base
pe kubectl delete image tutorial-image


comment "Start with the Cluster Store"
pe bat store.yaml
pe kubectl apply -f store.yaml

comment "The Cluster Stack"
pe bat stack.yaml
pe kubectl apply -f stack.yaml


comment "The Cluster Builders"
pe bat builder.yaml
pe kubectl apply -f builder.yaml

comment "The Build (image)"
pe bat image.yaml
pe kubectl apply -f image.yaml

pe kp image list
pe kp build logs tutorial-image

pe bat store-new.yaml
pe kubectl apply -f store-new.yaml
pei watch kp image list
pe kp build logs tutorial-image
#comment "#  Enter interactive mode..."
#cmd  # Run 'ls -l | grep example' to show result of 'openssl ...'