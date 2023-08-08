project="devops"
env="demo"
domain="punkerside.io"

export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export DOCKER_BUILDKIT=0
export docker_uid=$(id -u)
export docker_gid=$(id -g)
export docker_user=$(whoami)

img () {
    docker build -t ${project}-${env}:base -f docker/Dockerfile.base .
    docker build -t ${project}-${env}:terraform --build-arg IMG=${project}-${env}:base -f docker/Dockerfile.terraform .
    docker build -t ${project}-${env}:build --build-arg IMG=${project}-${env}:base -f docker/Dockerfile.build .
}

base () {
    echo "${docker_user}:x:${docker_uid}:${docker_gid}::/app:/sbin/nologin" > passwd
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/terraform/base:/app ${project}-${env}:terraform init
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/terraform/base:/app \
    -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
    ${project}-${env}:terraform apply -var="name=${project}-${env}" -var="domain=${domain}" -auto-approve
}

build () {
    echo "${docker_user}:x:${docker_uid}:${docker_gid}::/app:/sbin/nologin" > passwd
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/app:/app ${project}-${env}:build
}


release () {
    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
    docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}:latest --build-arg IMG=${project}-${env}:base -f docker/Dockerfile.latest .
    docker tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}:${GITHUB_RUN_ID}
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}:latest
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${project}-${env}:${GITHUB_RUN_ID}
}

deploy () {
    echo "${docker_user}:x:${docker_uid}:${docker_gid}::/app:/sbin/nologin" > passwd
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/terraform/app:/app ${project}-${env}:terraform init
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/terraform/app:/app \
    -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
    ${project}-${env}:terraform apply -var="name=${project}-${env}" -var="id_version=${GITHUB_RUN_ID}" -auto-approve
}

destroy () {
    echo "${docker_user}:x:${docker_uid}:${docker_gid}::/app:/sbin/nologin" > passwd
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/terraform/base:/app ${project}-${env}:terraform init
    docker run --rm -u ${docker_uid}:${docker_gid} -v ${PWD}/passwd:/etc/passwd:ro -v ${PWD}/terraform/base:/app \
    -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
    -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
    -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \
    ${project}-${env}:terraform destroy -var="name=${project}-${env}" -var="domain=${domain}" -auto-approve
}

"$@"