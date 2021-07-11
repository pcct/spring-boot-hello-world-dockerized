#!/bin/bash


# If there is a container based on image jenkins-docker, memorize it:
jenkinsContainer="nil"
for c in $(docker ps | sed '1d' | awk '{print $NF}'); do
  if docker inspect --format '{{ .Config.Image }}' "$c" | \
   grep -e 'jenkins-docker' >/dev/null 2>&1; then
    jenkinsContainer="$c"
  fi
done

# Get the image id of the jenkins-docker, memorize it:
jenkinsImageContainer="nil"
for c in $(docker images | sed '1d' | awk '{print $3}'); do
  if docker inspect --format '{{ .Config.Image }}' "$c" | \
   grep -e 'jenkins-docker' >/dev/null 2>&1; then
    jenkinsImageContainer="$c"
  fi
done


containers=$(docker ps | sed '1d' | awk '{print $NF}' | grep -v "$jenkinsContainer")
images=$(docker images -q | grep -v "$jenkinsContainer")


result=0
report="Initializing inspections ($(date +%Y-%m-%dT%H:%M:%S%:z))\n"

check_kernel_capabilities_are_restricted() {
  local description="Ensure that Linux kernel capabilities are restricted within containers"
  local fail=0
  local caps_containers=""
  for c in $containers; do
    container_caps=$(docker inspect --format 'CapAdd={{ .HostConfig.CapAdd}}' "$c")
    caps=$(echo "$container_caps" | tr "[:lower:]" "[:upper:]" | \
      sed 's/CAPADD/CapAdd/' | \
      sed -r "s/AUDIT_WRITE|CHOWN|DAC_OVERRIDE|FOWNER|FSETID|KILL|MKNOD|NET_BIND_SERVICE|NET_RAW|SETFCAP|SETGID|SETPCAP|SETUID|SYS_CHROOT|\s//g")

    if [ "$caps" != 'CapAdd=' ] && [ "$caps" != 'CapAdd=[]' ] && [ "$caps" != 'CapAdd=<no value>' ] && [ "$caps" != 'CapAdd=<nil>' ]; then
        caps_containers="$caps_containers $c"
        fail=1
    fi
  done

  if [ $fail -eq 0 ]; then
    report="$report PASS - $description\n"
  else
    report="$report FAIL - $description - Capabilities added for containers $caps_containers\n"
    result=1
  fi
}

check_health_check_instruction() {
  local description="Ensure that HEALTHCHECK instructions have been added to container images"
  local fail=0
  local no_health_images=""
  for img in $images; do
    if docker inspect --format='{{.Config.Healthcheck}}' "$img" 2>/dev/null | grep -e "<nil>" >/dev/null 2>&1; then
      fail=1
      imgName=$(docker inspect --format='{{.RepoTags}}' "$img" 2>/dev/null)
      if ! [ "$imgName" = '[]' ]; then
        no_health_images="$no_health_images $imgName"
      else
        no_health_images="$no_health_images $img"
      fi
    fi
  done

  if [ $fail -eq 0 ]; then
    report="$report PASS - $description\n"
 else
    report="$report FAIL - $description - Images without healthcheck: $no_health_images\n"
    result=1
  fi
}



main () {

# If container_users is empty, there are no running containers
if [ -z "$containers" ]; then
  echo " WARN - No containers running"
  return
fi


check_kernel_capabilities_are_restricted
check_health_check_instruction



echo "$report"
if [ $result -eq 0 ]; then
  return 0
else
  return 1
fi

}

main "$@"