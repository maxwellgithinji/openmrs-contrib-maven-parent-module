#!/bin/bash

# Verify arguments
set -e
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
  then
    echo "Usage: deployscript <group_id> <artifact_id> <version>"
    exit 1
fi

echo "Starting deploy script!"

# Startup arguments
group_id=${1}
artifact_id=${2}
version=${3}

# First clean install in base folder to ensure the artifact is present
mvn clean install

# Create new repository directory
base_dir=$(pwd)
target_dir=${base_dir}
parent_dir=$(dirname "$base_dir")

base_dir_name=${base_dir%%+(/)}
base_dir_name=${base_dir_name##*/}

repo_dir=${parent_dir}/${base_dir_name}-repository

# Copy git folder if the directory didn't exist yet
if ! [[ -d ${repo_dir} ]]
then
  mkdir ${repo_dir}
  echo "Copying git folder from original project..."
  cp -a ${base_dir}/.git ${repo_dir}/.git
fi

# Check out to new branch called repository
echo "Setting up repository branch and installing pom..."
pom_location=${target_dir}/pom.xml
cd ${repo_dir}
git checkout -B main
mvn install:install-file -DgroupId=${group_id} -DartifactId=${artifact_id} -Dversion=${version} -Dfile=${pom_location} -Dpackaging=pom -DgeneratePom=true -DlocalRepositoryPath=. -DcreateChecksum=true
cd ${base_dir}

# Commit and push
echo "Committing and pushing to repository branch..."
git add .
git commit -m "Release version ${version}"
git push origin main --force

echo "Done!"