#!/bin/sh
trap "clear; exec /bin/bash;" INT TERM

if ! curl --silent --fail --output /dev/null http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/; then
  echo "Starting Kubernetes, this may take a minute or so"
  while ! curl --silent --fail --output /dev/null http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/; do printf "." && sleep 1; done || break
  printf "done."
  echo ""
fi
clear
exec /bin/bash