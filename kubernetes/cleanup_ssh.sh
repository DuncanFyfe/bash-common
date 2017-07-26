#!/bin/bash
#Clean up stale known_hosts records when we redeploy a kubernetes
# infrastructure..

hostlist=""
list=$(echo "${hostlist}" | tr ',' '\n' | sort -u | tr '\n' ' ')

for m in ${list};
do
  ssh-keygen -f "${HOME}/.ssh/known_hosts" -R ${m}
done
