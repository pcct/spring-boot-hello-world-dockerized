#!/bin/bash


# If there is a container based on image jenkins-docker, memorize it:
jenkinsContainer="nil"
for c in $(docker ps | sed '1d' | awk '{print $NF}'); do
  if docker inspect --format '{{ .Config.Image }}' "$c" | \
   grep -e 'jenkins-docker' >/dev/null 2>&1; then
    jenkinsContainer="$c"
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
    report="$report FAIL - $description - Capabilities added for containers: $caps_containers\n"
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


check_host_system_directories_are_not_mounted() {
  local description="Ensure sensitive host system directories are not mounted on containers"
  local fail=0
  local sensitive_mount_containers=""

  # List of sensitive directories to test for. Script uses new-lines as a separator.
  # Note the lack of identation. It needs it for the substring comparison.
  sensitive_dirs='/
/boot
/dev
/etc
/lib
/proc
/sys
/usr'

  for c in $containers; do
    volumes=$(docker inspect --format '{{ .Mounts }}' "$c")
    if docker inspect --format '{{ .VolumesRW }}' "$c" 2>/dev/null 1>&2; then
      volumes=$(docker inspect --format '{{ .VolumesRW }}' "$c")
    fi
    # Go over each directory in sensitive dir and see if they exist in the volumes
    for v in $sensitive_dirs; do
      if echo "$volumes" | grep -e "{.*\s$v\s.*true\s.*}" 2>/tmp/null 1>&2; then
        fail=1
        sensitive_mount_containers="$sensitive_mount_containers $c:$v"
      fi
    done
  done

  if [ $fail -eq 0 ]; then
    report="$report PASS - $description\n"
 else
    report="$report FAIL - $description - Containers with sensitive directories mounted: $no_health_images\n"
    result=1
  fi
}

check_container_without_additional_privileges() {
  local description="Ensure that the container is restricted from acquiring additional privileges"
  local fail=0
  local addprivs_containers=""
  for c in $containers; do
    if ! docker inspect --format 'SecurityOpt={{.HostConfig.SecurityOpt }}' "$c" | grep 'no-new-privileges' 2>/dev/null 1>&2; then
      fail=1
      addprivs_containers="$addprivs_containers $c"
    fi
  done

  if [ $fail -eq 0 ]; then
    report="$report PASS - $description\n"
  else
    report="$report FAIL - $description - Containers without restricted privileges: $addprivs_containers\n"
    result=1
  fi
}


main () {

# If container_users is empty, there are no running containers
if [ -z "$containers" ]; then
  echo " WARN - No containers running"
  return
fi

#custom inspections
check_kernel_capabilities_are_restricted
check_health_check_instruction
check_host_system_directories_are_not_mounted
check_container_without_additional_privileges


echo "$report"
return $result

}

main "$@"