project="devops"
env="demo"

export DOCKER_BUILDKIT=0

base () {
    docker build -t ${project}-${env}:base -f docker/Dockerfile.base .
    docker build -t ${project}-${env}:terraform --build-arg IMG=${project}-${env}:base -f docker/Dockerfile.terraform .
}

"$@"