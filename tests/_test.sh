#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"

printf "╭──────────────────╮\n│ \033[0;95mdivan test suite\033[0m │\n╰──────────────────╯\n"
printf "\033[0;95mWorking from '\033[0m%s\033[0;95m'.\033[0m\n" "$(dirname "$DIR")"
printf "\033[0;95mDoes this directory match your repository location ? If not, please make sure you are running tests from the correct folder.\033[0m\n"

printf "\n→ \033[0;33mStarting the test container \033[0m(this step can take a little while)\033[0;33m...\033[0m"
imageID=""
log=$( docker-compose -f docker-compose.yml up -d --build --force-recreate divan-test 2>&1) || {
  printf "\r\033[K\033[0;31m✘ Failed to setup docker image\033[0m : %s\033[0m\n" "$log"
  exit 1
}

imageID=$(docker ps -aqf "name=^divan-test$")
printf "\r\033[K\033[0;32m✔\033[0;34m Successfully started docker container with ID \033[0m%s\033[0;34m.\033[0m\n" "$imageID"

printf "\n→ \033[0;33mCopying test script to docker container...\033[0m"
docker cp -L "$DIR/." divan-test:/root/test_files
docker exec "divan-test" chmod -R 0777 /root/test_files

printf "\r\033[K\033[0;36mRunning tests for '\033[0mscripts/check_config.sh\033[0;36m'.\033[0m\n"
docker exec "divan-test" bats --pretty /root/test_files/check_config.bats

printf "\033[0;36mRunning tests for '\033[0mscripts/create_cluster.sh\033[0;36m'.\033[0m\n"
docker exec "divan-test" bats --pretty /root/test_files/create_cluster.bats

printf "→ \033[0;33mKilling container...\033[0m"
output="$(docker stop divan-test)" || {
  printf "%s\n" "$output" 1>&2
  exit 1
}
output="$(docker rm divan-test)" || {
  printf "%s\n" "$output" 1>&2
  exit 1
}
printf "\r\033[K\033[0;32m✔\033[0;34m Successfully killed \033[0m%s\033[0;34m container.\033[0m" "$imageID"

printf "\n→ \033[0;33mStarting the test container \033[0m(this step can take a little while)\033[0;33m...\033[0m"
imageID=""
log=$( docker-compose -f docker-compose.yml up -d --build --force-recreate divan-test 2>&1) || {
  printf "\r\033[K\033[0;31m✘ Failed to setup docker image\033[0m : %s\033[0m\n" "$log"
  exit 1
}

imageID=$(docker ps -aqf "name=^divan-test$")
printf "\r\033[K\033[0;32m✔\033[0;34m Successfully started docker container with ID \033[0m%s\033[0;34m.\033[0m\n" "$imageID"

printf "\n→ \033[0;33mCopying test script to docker container...\033[0m"
docker cp -L "$DIR/." divan-test:/root/test_files
docker exec "divan-test" chmod -R 0777 /root/test_files

printf "\r\033[K\033[0;36mRunning tests for '\033[0mscripts/create_cluster_2.sh\033[0;36m'.\033[0m\n"
docker exec "divan-test" bats --pretty /root/test_files/create_cluster_2.bats

printf "\033[0;36mRunning tests for '\033[0mscripts/create_buckets.sh\033[0;36m'.\033[0m\n"
printf "* \033[0;95mworking with safe mode off\033[0m\n"
docker exec "divan-test" bats --pretty /root/test_files/create_buckets.bats
printf "* \033[0;95mworking with safe mode on\033[0m\n"
docker exec "divan-test" bats --pretty /root/test_files/create_buckets_safe.bats

printf "→ \033[0;33mKilling container...\033[0m"
output="$(docker stop divan-test)" || {
  printf "%s\n" "$output" 1>&2
  exit 1
}
output="$(docker rm divan-test)" || {
  printf "%s\n" "$output" 1>&2
  exit 1
}
printf "\r\033[K\033[0;32m✔\033[0;34m Successfully killed \033[0m%s\033[0;34m container.\033[0m\n" "$imageID"