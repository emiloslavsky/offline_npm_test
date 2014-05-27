#!/bin/bash
# tested on Ubuntu 12.04
# usage: 
# ./doit.sh
#   npm install from cache with shrinkwrap fails when networking is disabled
# ./doit.sh noshrinkwrap 
#   npm install from cache without shrinkwrap works when networking is disabled


curl http://nodejs.org/dist/v0.10.28/node-v0.10.28-linux-x64.tar.gz | tar xvz
TPATH="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH="${TPATH}/node-v0.10.28-linux-x64/bin:${NUCLEUS_HOME}/node_modules/.bin:$PATH"

# i == 1: populate cache, disable networking
# i == 2: try npm install with prefilled cache and NPM_CONFIG_CACHE-MIN=999999
# i == 3: try npm install with prefilled cache and NPM_CONFIG_REGISTRY=""
# i == 4: try npm install with prefilled cache and NPM_CONFIG_REGISTRY=null
# then enables networking back
for i in $(seq 1 4);
do
  echo "test =-= ${i}"
  NPM_CACHE=${TPATH}/npm_cache${i}
  rm -rf ${NPM_CACHE}

  # first iteration constructs npm cache, next iterations copy it
  if [ $i != 1 ]; then
    cp -a ${TPATH}/npm_cache1 ${NPM_CACHE}
  fi

  rm -rf test${i}
  mkdir -p test${i}
  cp package.json test${i}
  if [ "$1" != "noshrinkwrap" ]; then
    echo "cp npm-shrinkwrap.json test${i}"
    cp npm-shrinkwrap.json test${i}
  fi
  cd test${i}

  if [ "$i" == "1" ]; then
    E="NPM_CONFIG_CACHE=${NPM_CACHE}"
    E2="NPM_CONFIG_CACHE=${NPM_CACHE}"
  elif [ "$i" == "2" ]; then
    E="NPM_CONFIG_CACHE-MIN=999999" 
    E2="NPM_CONFIG_CACHE=${NPM_CACHE}"
  elif [ "$i" == "3" ]; then
    E="NPM_CONFIG_REGISTRY=\"\""
    E2="NPM_CONFIG_CACHE=${NPM_CACHE}"
  elif [ "$i" == "4" ]; then
    E="NPM_CONFIG_REGISTRY=null"
    E2="NPM_CONFIG_CACHE=${NPM_CACHE}"
  fi

  time env "${E}" "${E2}" npm config ls -l 2>&1 |tee out.log
  time env "${E}" "${E2}" npm install  2>&1 |tee -a out.log

  cd ..

  # turn networking off after the first iteration
  if [ "$i" == "1" ]; then
    sudo  ifconfig eth0 down
    sleep 20;
  fi
done
# turn networking back on
sudo  ifconfig eth0 up
