ts := $(shell /bin/date "+%s")

check-variables:
ifndef PROJECT
  $(error PROJECT is undefined)
endif
ifndef K8S_VERSION
  $(error K8S_VERSION is undefined)
endif
ifndef MINIKUBE_VERSION
  $(error MINIKUBE_VERSION is undefined)
endif

build: check-variables
	packer build -var 'project_id=${PROJECT}' -var 'minikube_version=${MINIKUBE_VERSION}' -var 'k8s_version=${K8S_VERSION}' packer.json

force-build: check-variables
	packer build -force -var 'project_id=${PROJECT}' -var 'minikube_version=${MINIKUBE_VERSION}' -var 'k8s_version=${K8S_VERSION}' packer.json
