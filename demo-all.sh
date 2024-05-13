#!/bin/bash

# Include the "demo-magic" helpers
source demo-magic.sh
initial_wd=`pwd`
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
TYPE_SPEED=30
DEMO_COMMENT_COLOR=$GREEN
export NO_COLOR=1
function comment() {
  cmd=$DEMO_COMMENT_COLOR$1$COLOR_RESET
  echo -en "$cmd"; echo ""
}

clear

comment "# Setup:"
docker rmi registry.gcp.ellin.net/library/image-built-with-jib -f
docker rmi registry.gcp.ellin.net/library/simple-server -f
docker rmi registry.gcp.ellin.net/library/java-demo -f
docker rmi registry.gcp.ellin.net/library/java-app -f

pei 'cd java-app'
pe './mvnw clean package'

comment "# Create the docker image"
pe 'bat Dockerfile'
pe 'docker build -t registry.gcp.ellin.net/library/java-demo .'
pe 'dive registry.gcp.ellin.net/library/java-demo --config $initial_wd/dive.yaml'

comment "Rebuild the image adding a file"
pei 'bat Dockerfile2'
pe 'docker build -f Dockerfile2 -t registry.gcp.ellin.net/library/java-demo .'
pe 'dive registry.gcp.ellin.net/library/java-demo --config $initial_wd/dive.yaml'

comment "Rebuild the originalDockerfile"
pe 'docker build -t registry.gcp.ellin.net/library/java-demo .'

comment "Rebuild the alternate Dockfile2a"
pei 'bat Dockerfile2a'
pe 'docker build -f Dockerfile2a -t registry.gcp.ellin.net/library/java-demo .'

comment "Unpack the uber jar"
pei mkdir target/dependency
pei cd target/dependency
pe 'jar -xf ../*.jar'
pei 'ls -la'
pei 'cd ../..'
pei 'bat Dockerfile3'
pe 'docker build -f Dockerfile3 -t registry.gcp.ellin.net/library/java-demo .'
pe 'dive registry.gcp.ellin.net/library/java-demo --config $initial_wd/dive.yaml'

comment "Let's build the Jar with Jib"
pe 'mvn compile jib:build'
comment "Must Pull the Container as Local Docker Daemon was not used"
pe "docker pull registry.gcp.ellin.net/library/java-demo"
pe 'dive registry.gcp.ellin.net/library/java-demo --config $initial_wd/dive.yaml'

comment "Let's build the Jar with a Cloud Native Buildpack"
pe "pack config default-builder  paketobuildpacks/builder-jammy-base"
#pei cd java-app
pe "pack build registry.gcp.ellin.net/library/java-app"
pe 'dive registry.gcp.ellin.net/library/java-app --config $initial_wd/dive.yaml'

pei cd ../simple-server
comment "another look at CNB"
comment "no Dockerfile"
pei "ls -la"
pe 'pack build registry.gcp.ellin.net/library/simple-server' 
pe 'dive registry.gcp.ellin.net/library/simple-server --config $initial_wd/dive.yaml'

comment "Now a look at Kpack"

pei cd ../kpack
comment "lets cleanup the cluster"
pei 'kubectl delete builder my-builder'
pei 'kubectl delete clusterstacks base'
pei 'kubectl delete image tutorial-image'


comment "Start with the Cluster Store"
pe 'bat store.yaml'
pe 'kubectl apply -f store.yaml'

comment "The Cluster Stack"
pe 'bat stack.yaml'
pe 'kubectl apply -f stack.yaml'


comment "The Cluster Builders"
pe 'bat builder.yaml'
pe 'kubectl apply -f builder.yaml'

comment "The Image "
pe 'bat image.yaml'
pe 'kubectl apply -f image.yaml'

pe 'kp image list'
pe 'kp build logs tutorial-image'

comment "lets update the stack"
pe 'bat stack-new.yaml'
pe 'kubectl apply -f stack-new.yaml'
pei 'watch kp image list'
pe 'kp build logs tutorial-image'
pe 'kp build list'


#comment "#  Enter interactive mode..."
#cmd  # Run 'ls -l | grep example' to show result of 'openssl ...'