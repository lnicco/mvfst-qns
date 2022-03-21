#!/usr/bin/env bash
# use this to build the image from latest master
# NOTE: it clones the repo from scratch

set -e
set -o nounset

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

mkdir -p ${DIR}/auto/logs

cd ${DIR}/auto/
rm -rf mvfst-qns || true
git clone https://github.com/lnicco/mvfst-qns.git
cd mvfst-qns

DATE=$(date +"%Y%m%d_%H%M%S")
IMAGEHASH=$(sudo docker build . --no-cache --pull | tee ../logs/build.${DATE} | grep "Successfully built" | cut -d " " -f 3)
if [ -z $IMAGEHASH ]; then
    echo "Image build failed or not necessary: check logs/build.${DATE}"
else
    sudo docker tag ${IMAGEHASH} lnicco/mvfst-qns:latest
    sudo docker push lnicco/mvfst-qns
fi
sudo docker image prune -f -a

