ts := $(shell /bin/date "+%s")

check-variables:
ifndef PROJECT
  $(error PROJECT is undefined)
endif

build: check-variables
	packer build -var 'project_id=${PROJECT}' kubernetes.json

force-build: check-variables
	packer build -force -var 'project_id=${PROJECT}' kubernetes.json
