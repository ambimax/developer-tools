# ambimax® Developer Tools

Some small tools to ease developer life.

## Install developer tools

**docker deploy**

```
curl -o /usr/local/bin/docker-deploy https://raw.githubusercontent.com/ambimax/developer-tools/master/docker-deploy.sh && \ 
chmod +x /usr/local/bin/docker-deploy
```


## Docker Deployment

Deploys project packages, pulls defined database dump and starts docker containers.

```
deploy-docker --package-url=tests/package.tar.gz \
    --database-url=tests/database.sql.gz \
    --dir=/tmp/docker-deploy-test \
    --extra-package \
    --start-containers
```

Sample packages are in this repo:
 - tests/package.tar.gz
 - tests/package.extra.gz
 - tests/database.tar.gz
 
