#!/usr/bin/env bash

realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

TESTS_PATH=`dirname $(realpath "$0")`
BASE_PATH=`dirname $TESTS_PATH`

if [ -d "/tmp/docker-deploy-test" ]; then
    echo "Remove existing test environment"
    (cd /tmp/docker-deploy-test && docker-compose down -v && rm -rf /tmp/docker-deploy-test)
    echo
    echo
fi

cd $BASE_PATH

./docker-deploy.sh --package-url=tests/assets/package.tar.gz \
    --database-url=tests/assets/database.sql.gz \
    --dir=/tmp/docker-deploy-test \
    --extra-package \
    --start-containers \
    --project-init="docker-compose exec nginx sh -c \"echo 'docker::init' > /var/www/htdocs/init.html\""
