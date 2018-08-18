#!/usr/bin/env bash
# Docker Deployment Script
# Author: Tobias Schifftner, ambimax® GmbH
# Created: 2018/08

COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_GREEN="\033[0;32m"
COLOR_OCHRE="\033[38;5;95m"
COLOR_BLUE="\033[0;34m"
COLOR_WHITE="\033[0;37m"
COLOR_RESET="\033[0m"

function error_exit {
    echo ""
	echo -e "${COLOR_RED}${1}${COLOR_RESET}" 1>&2
	echo ""
	exit 1
}

function usage_exit {
    echo ""
    echo -e "${COLOR_RED}${1}${COLOR_RESET}" 1>&2
    show_help 1
}

function download {
    URL=$1
    DEST=$2

    # copy local file
    if [ -f "${URL}" ] ; then
        cp "${URL}" "${DEST}" || error_exit "Error while copying ${URL} to ${DEST}"

    # download from url
    elif [[ "${URL}" =~ ^https?:// ]] ; then
        if [ ! -z "${USERNAME}" ] && [ ! -z "${PASSWORD}" ] ; then
            CREDENTIALS="--user=${USERNAME} --password=${PASSWORD}"
        fi
        echo "Downloading package via http"
        wget --auth-no-challenge ${CREDENTIALS} "${URL}" -O "${DEST}" || error_exit "Error while downloading ${URL} to ${DEST}"

    # download from s3 storage
    elif [[ "${URL}" =~ ^s3:// ]] ; then
        echo -n "Downloading base package via S3"

        PROFILEPARAM=""
        if [ ! -z "${AWSCLIPROFILE}" ] ; then
            PROFILEPARAM="--profile ${AWSCLIPROFILE}"
        fi

        aws ${PROFILEPARAM} s3 cp "${URL}" "${DEST}" || error_exit "Error while downloading base package from S3"
    fi

    # check if file is there
    if [ ! -f "${DEST}" ]; then
        error_exit "Download ${URL} to ${DEST} failed!"
    fi
}


function show_help {
    echo ""
    echo "Usage:"
    echo ""
    echo "$0 \ "
    echo "      --package-url=<packageUrl> \ "
    echo "      --database-url=<databaseUrl> \ "
    echo "      --install-dir=<installDir> \ "
    echo "      [--env=<environment>] \ "
    echo "      [--extra-package] \ "
    echo "      [--start-containers] \ "
    echo "      [--project-init=<initCommand>] \ "
    echo "      [--username=<username>] \ "
    echo "      [--password=<password>] \ "
    echo "      [--aws-profile=<awsProfile>] \ "
    echo ""
    echo "--package-url         Path to the build package (http, S3 or local file)"
    echo "--database-url        Path to the database package (http, S3 or local file)"
    echo "--install-dir                 Target dir"
    echo "--env                 Environment docker, devbox, staging (optional, default: docker)"
    echo "--extra-package       Install extra build package (optional)"
    echo "--start-containers    Start docker containers after downloading (optional)"
    echo "--project-init        Run a command to init project (optional)"
    echo "--username            Username for download credentials (optional)"
    echo "--password            Password for download credentials (optional)"
    echo "--aws-profile         Define aws profile (optional)"
    echo ""
    echo "--version             Show version"
    echo ""

    exit $1
}

ENVIRONMENT=docker
AWSCLIPROFILE=''
EXTRA=0
USES3CMD=0
START_CONTAINERS=0

while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        --package-url=?*)
            PACKAGEURL=${1#*=}
            ;;
        --database-url=?*)
            DATABASEURL=${1#*=}
            ;;
        --install-dir=?*)
        	_PATH=${1#*=}
        	INSTALL_DIR="${_PATH/#\~/$HOME}"
            ;;
        --env=?*)
            ENVIRONMENT=${1#*=}
            ;;
        --username=?*)
            USERNAME=${1#*=}
            ;;
        --password=?*)
            PASSWORD=${1#*=}
            ;;
        --aws-profile=?*)
            AWSCLIPROFILE=${1#*=}
            ;;
        --extra-package)
            EXTRA=1
            ;;
        --start-containers)
            if [ -x "$(command -v docker ps)" ]; then error_exit "docker is not installed"; fi
            if [ -x "$(command -v docker-compose ps)" ]; then error_exit "docker-compose is not installed"; fi
            START_CONTAINERS=1
            ;;
        --project-init=?*)
            PROJECT_INIT=${1#*=}
            ;;
        --version)
            echo " 1.0.0 docker-deploy by ambimax® GmbH"
            echo ""
            exit 0;
            ;;
        *) # no more options, break out of loop
        break
    esac
    shift
done


if [ -z "${PACKAGEURL}" ]; then usage_exit "ERROR: Please provide package url (e.g. --package-url=s3://mybucket/package.tar.gz)"; fi
if [ -z "${DATABASEURL}" ]; then usage_exit "ERROR: Please provide database url (e.g. --database-url=s3://mybucket/database.sql.gz)"; fi
if [ -z "${INSTALL_DIR}" ]; then usage_exit "ERROR: Please provide a target dircteory (e.g. --dir=/var/www/demo/)"; fi
if [ -z "${ENVIRONMENT}" ]; then usage_exit "ERROR: Please provide an environment code (e.g. --env=staging)"; fi

# Create tmp dir and make sure it's going to be deleted in any case
TMPDIR=`mktemp -d`
function cleanup {
    echo "Removing temp dir ${TMPDIR}"
    rm -rf "${TMPDIR}"
}
trap cleanup EXIT

EXTRAPACKAGEURL=${PACKAGEURL/.tar.gz/.extra.tar.gz}

echo "Creating install folder"
echo "mkdir ${INSTALL_DIR}"
mkdir "${INSTALL_DIR}" || error_exit "Error while creating install folder"

########################################################################################################################
# Step 1: get the package via http, S3 or local file
########################################################################################################################
echo "Downloading project package..."
download "${PACKAGEURL}" "${TMPDIR}/package.tar.gz"
if [ "${EXTRA}" == 1 ] ; then
    echo "Downloading extra package..."
    download "${EXTRAPACKAGEURL}" "${TMPDIR}/package.extra.tar.gz"
fi



########################################################################################################################
# Step 2: extract files into release folder
########################################################################################################################
echo "Extracting base package"
tar xzf "${TMPDIR}/package.tar.gz" -C "${INSTALL_DIR}" || error_exit "Error while extracting base package"

if [ "${EXTRA}" == 1 ] ; then
    echo "Extracting extra package on top of base package"
    tar xzf "${TMPDIR}/package.extra.tar.gz" -C "${INSTALL_DIR}" || error_exit "Error while extracting extra package"
fi



########################################################################################################################
# Step 3: Stop when start containers is disabled
########################################################################################################################
if [ "${START_CONTAINERS}" == 0 ] ; then
    echo "--> THIS PACKAGE IS READY FOR FURTHER ACTIONS! <--"
    exit 0
fi



########################################################################################################################
# Step 4: Download database
########################################################################################################################
echo "Downloading database package..."
download "${DATABASEURL}" "${INSTALL_DIR}/database.sql.gz"



########################################################################################################################
# Step 5: Start docker containers
########################################################################################################################
if [ ! -f "${INSTALL_DIR}/docker-compose.yml" ]; then
	error_exit "This package does not yet support docker containers";
fi
echo "Starting docker containers"
cd "${INSTALL_DIR}" || error_exit "Cannot enter installation dir"
docker-compose up -d



########################################################################################################################
# Step 6: Project initialization
########################################################################################################################
if [ ! -z "${PROJECT_INIT}" ]; then
    echo "Project initialization"
    eval $PROJECT_INIT
fi



echo
echo "Successfully completed installation."
echo