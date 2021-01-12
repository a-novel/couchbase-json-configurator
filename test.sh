#!/bin/sh

DIR="$(pwd)"

printf "╭──────────────────╮\n│ \033[0;95mdivan test suite\033[0m │\n╰──────────────────╯\n"
printf "\033[0;95mWorking from '\033[0m%s\033[0;95m'.\033[0m\n" "$DIR"
printf "\033[0;95mDoes this directory match your repository location ? If not, please make sure you are running tests from the correct folder.\033[0m\n"

printf "\n→ \033[0;33mStarting the test container \033[0m(this step can take a little while)\033[0;33m...\033[0m"
log=$( docker-compose -f docker-compose.yml up -d --build --force-recreate divan-test 2>&1) || {
  printf "\r\033[K\033[0;31m✘ Failed to setup docker image\033[0m : %s\033[0m\n" "$log"
  exit 1
}

imageID=$(docker ps -aqf "name=^divan-test$")
printf "\r\033[K\033[0;32m✔\033[0;34m Successfully started docker container with ID \033[0m%s\033[0;34m.\033[0m\n" "$imageID"

printf "\r\033[K\033[0;36mRunning tests.\033[0m\n"
docker exec "divan-test" sh -c "cd /root/DIVAN_scripts && sh scripts/test.sh"

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