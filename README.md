<h1 align="center">Ambimax® Developer Tools</h1>

<p align="center">
  Some small tools to ease developer life.
</p>
<p align="center">
    <a href="https://travis-ci.org/ambimax/developer-tools"><img alt="Build Status" src="https://travis-ci.org/ambimax/developer-tools.svg?branch=master"></a>
</p>

# ambimax® Developer Tools

[![Build Status](https://travis-ci.org/ambimax/developer-tools.svg?branch=master)](https://travis-ci.org/ambimax/developer-tools)

Some small tools to ease developer life.

## Install developer tools

**docker deploy**

```
curl -o /usr/local/bin/docker-deploy https://raw.githubusercontent.com/ambimax/developer-tools/master/docker-deploy.sh
chmod +x /usr/local/bin/docker-deploy
```


## Docker Deployment

Deploys project packages, pulls defined database dump and starts docker containers.

```
docker-deploy --package-url=tests/assets/package.tar.gz \
    --database-url=tests/assets/database.sql.gz \
    --install-dir=/tmp/docker-deploy-test \
    --extra-package \
    --start-containers \
    --project-init="docker-compose exec nginx sh -c \"echo 'docker::init' > /var/www/htdocs/init.html\""
```

Sample packages are in this repo:
 - tests/package.tar.gz
 - tests/package.extra.gz
 - tests/database.tar.gz
 
