.EXPORT_ALL_VARIABLES:
.ONESHELL:
.SILENT:

MAKEFLAGS += --no-builtin-rules --no-builtin-variables

###############################################################################
# Variables
###############################################################################

google_project ?= lab5-wvai-dev1

###############################################################################
# Settings
###############################################################################

VERSION := $(file < VERSION)

app_id := wvai

google_organization :=
google_billing_account :=

gke_name := $(app_id)-01

root_dir := $(abspath .)

terraform_dir := $(root_dir)/terraform
terraform_config := $(root_dir)/config/$(google_project)
terraform_tfvars := $(terraform_config)/terraform.tfvars
terraform_output := $(terraform_config)/$(google_project).json
terraform_bucket := terraform-$(google_project)
terraform_prefix := $(app_id)

ifeq ($(wildcard $(terraform_tfvars)),)
  $(error ==> Missing configuration file $(terraform_tfvars) <==)
endif

###############################################################################
# Info
###############################################################################

.PHONY: certs config terraform kubernetes

default: help settings

help:
	$(call header,Help)
	$(call help,make google,Configure Google CLI)
	$(call help,make google-auth,Authenticate Google CLI)
	$(call help,make terraform,Run Terraform plan and apply)
	$(call help,make release, Trigger GitHub pipeline deployment)

settings: terraform-config
	$(call header,Settings)
	$(call var,repo_version,$(VERSION))
	$(call var,google_project,$(google_project))
	$(call var,gcloud_project,$(shell gcloud config list --format=json | jq -r '.core.project'))

###############################################################################
# End-to-End Pipeline
###############################################################################

deploy : terraform

remove: terraform-destroy

clean: terraform-clean gke-clean

###############################################################################
# Terraform
###############################################################################

terraform: terraform-plan prompt terraform-apply

terraform-fmt: terraform-version
	$(call header,Check Terraform Code Format)
	cd $(terraform_dir)
	terraform fmt -check -recursive

terraform-config:
	ln -rfs $(terraform_tfvars) $(terraform_dir)/terraform.tfvars

terraform-validate:
	$(call header,Validate Terraform)
	cd $(terraform_dir)
	terraform validate

terraform-init: terraform-fmt terraform-config
	$(call header,Initialize Terraform)
	cd $(terraform_dir)
	terraform init -upgrade -input=false -reconfigure -backend-config="bucket=$(terraform_bucket)" -backend-config="prefix=$(terraform_prefix)"

terraform-plan: terraform-init terraform-validate
	$(call header,Run Terraform Plan)
	cd $(terraform_dir)
	terraform plan -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-apply: terraform-init terraform-validate
	$(call header,Run Terraform Apply)
	set -e
	cd $(terraform_dir)
	terraform apply -auto-approve -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-destroy: terraform-init
	$(call header,Run Terraform Apply)
	cd $(terraform_dir)
	terraform apply -destroy -input=false -refresh=true -var-file="$(terraform_tfvars)"

terraform-clean:
	$(call header,Delete Terraform providers and state)
	-rm -rf $(terraform_dir)/.terraform $(terraform_dir)/.terraform.lock.hcl

terraform-show:
	cd $(terraform_dir)
	terraform show

terraform-version:
	$(call header,Terraform Version)
	terraform version

terraform-state-list:
	cd $(terraform_dir)
	terraform state list

terraform-state-recursive:
	gsutil ls -r gs://$(terraform_bucket)/**

terraform-state-versions:
	gsutil ls -a gs://$(terraform_bucket)/$(terraform_prefix)/default.tfstate

terraform-state-unlock:
	gsutil rm gs://$(terraform_bucket)/$(terraform_prefix)/default.tflock

terraform-bucket:
	$(call header,Create Terrafomr state GCS bucket)
	set -e
	gsutil mb -p $(google_project) -l $(google_region) -b on gs://$(terraform_bucket) || true
	gsutil ubla set on gs://$(terraform_bucket)
	gsutil versioning set on gs://$(terraform_bucket)

###############################################################################
# Google CLI
###############################################################################

google_region := $(shell grep google_region $(terraform_tfvars) | cut -d '"' -f2)

google: google-config

google-auth:
	$(call header,Configure Google CLI)
	gcloud auth revoke --all
	gcloud auth login --update-adc --no-launch-browser

google-config:
	set -e
	gcloud auth application-default set-quota-project $(google_project)
	gcloud config set core/project $(google_project)
	gcloud config set compute/region $(google_region)
	gcloud config list

google-project:
	$(call header,Create Google Project)
	set -e
	gcloud projects create $(google_project) --organization=$(google_organization)
	gcloud billing projects link $(google_project) --billing-account=$(google_billing_account)
	gcloud services enable compute.googleapis.com --project=$(google_project)
	gcloud services enable cloudresourcemanager.googleapis.com --project=$(google_project)

###############################################################################
# Kubernetes (GKE)
###############################################################################

KUBECONFIG ?= $(HOME)/.kube/config

kube: kube-clean kube-auth

kube-auth: $(KUBECONFIG)

$(KUBECONFIG):
	$(call header,Get Kubernetes credentials)
	set -e
	gcloud container clusters get-credentials --zone=$(google_region) $(gke_name)
	kubectl cluster-info

kube-clean:
	$(call header,Delete Kubernetes credentials)
	rm -rf $(KUBECONFIG)

###############################################################################
# Checkov
###############################################################################

.checkov.baseline:
	echo "{}" >| $@

checkov: .checkov.baseline
	$(call header,Run Checkov with baseline)
	checkov --baseline .checkov.baseline

checkov-all:
	$(call header,Run Checkov NO baseline)
	checkov --quiet

checkov-baseline:
	$(call header,Create Checkov baseline)
	checkov --quiet --create-baseline

checkov-clean:
	rm -rf .checkov.baseline

checkov-install:
	pipx install checkov

checkov-upgrade:
	pipx upgrade checkov

###############################################################################
# Repo Version
###############################################################################

.PHONY: version commit merge

version:
	version=$$(date +%Y.%m.%d-%H%M)
	echo "$$version" >| VERSION
	$(call header,Version: $$(cat VERSION))
	git add --all

commit: version
	git commit -m "$$(cat VERSION)"

merge:
	gh pr merge --squash --delete-branch $$(git rev-parse --abbrev-ref HEAD)

###############################################################################
# Colors and Headers
###############################################################################

TERM := xterm-256color

black := $$(tput setaf 0)
red := $$(tput setaf 1)
green := $$(tput setaf 2)
yellow := $$(tput setaf 3)
blue := $$(tput setaf 4)
magenta := $$(tput setaf 5)
cyan := $$(tput setaf 6)
white := $$(tput setaf 7)
reset := $$(tput sgr0)

define header
echo "$(blue)==> $(1) <==$(reset)"
endef

define help
echo "$(green)$(1)$(reset) - $(white)$(2)$(reset)"
endef

define var
echo "$(magenta)$(1)$(reset): $(yellow)$(2)$(reset)"
endef

prompt:
	echo -n "$(blue)Continue?$(reset) $(yellow)(yes/no)$(reset)"
	read -p ": " answer && [ "$$answer" = "yes" ] || exit 1

###############################################################################
# Errors
###############################################################################
ifeq ($(shell which gcloud),)
  $(error ==> Missing Google CLI https://cloud.google.com/sdk/docs/install <==)
endif

ifeq ($(shell which terraform),)
  $(error ==> Missing terraform https://www.terraform.io/downloads <==)
endif

ifeq ($(shell which helm),)
  $(error ==> Missing helm https://helm.sh/ <==)
endif