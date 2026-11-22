#!/bin/bash
set -e

# load variables , commonly used ones are here except sensitive ones
export PE_CLUSTER_NAME="RNO-SPOC007-3"
export PRIMARY_SUBNET_PREFIX="10.8.50"
# run mgmt.sh?
export INSTALL_NKP_MGMT_CLUSTER=true
export DEPLOY_NAI=true
export DEPLOY_GITLAB=true
# clean up current state and workspace if true
export DESTRUCTIVE_MODE=true
export APPLY_TERRAFORM=true
source ./env/.sensitive.env
source ./env/environment.env
# variable for the vms like bastion etc
source ./env/vm-setup.env
# for NKP and NAI related variables
source ./env/install.env
# verification
export PTR=$(echo "$PRIMARY_SUBNET_PREFIX" | awk -F. '{ print $3 "." $2 "." $1 }')
echo "PRIMARY_SUBNET_PREFIX: $PRIMARY_SUBNET_PREFIX"
echo "PE_CLUSTER_NAME: $PE_CLUSTER_NAME"
# echo "NUTANIX_PASSWORD: $NUTANIX_PASSWORD"
echo "NUTANIX_USER: $NUTANIX_USER"
echo "PTR: $PTR"
echo "VM_USER: $VM_USER"
# echo "VM_USER_PASSWORD: $VM_USER_PASSWORD"

# Determine HOSTING_URL based on PE_CLUSTER_NAME prefix
case "$PE_CLUSTER_NAME" in
   PHX*)
       export HOSTING_URL="${PHX_HOSTING_URL}"
       ;;
   DM3*)
       export HOSTING_URL="http://10.55.251.38"
       ;;
# BLR does not have any replication, so we default to PHX
#    BLR*)
#        export HOSTING_URL="XXX"
#        ;;
   *)
       # Default to PHX if none matched, e.g. RNO
       export HOSTING_URL="${PHX_HOSTING_URL}"
       ;;
esac
echo "HOSTING_URL: $HOSTING_URL"

# Derieved variables from cluster name, may break when hpoc changes the naming convention
# for most hpoc env, prefix are the same
export SECONDARY_SUBNET_PREFIX=$PRIMARY_SUBNET_PREFIX
export DHCP_SUBNET_PREFIX=$PRIMARY_SUBNET_PREFIX
export PC_OCTET=7
export AD_OCTET=6
export CVM_OCTET=37
# IP address for bastion, registry and gitlab VM
export BASTION_OCTET=90
export REGISTRY_OCTET=91
export GITLAB_OCTET=92

export PRIMARY_SUBNET_NAME="primary-$PE_CLUSTER_NAME"
export SECONDARY_SUBNET_NAME="secondary-$PE_CLUSTER_NAME"
export PC_ENDPOINT=$PRIMARY_SUBNET_PREFIX.$PC_OCTET
export AD_ENDPOINT=$PRIMARY_SUBNET_PREFIX.$AD_OCTET
export BASTION_IP=$PRIMARY_SUBNET_PREFIX.$BASTION_OCTET
export REGISTRY_IP=$PRIMARY_SUBNET_PREFIX.$REGISTRY_OCTET
export GITLAB_IP=$PRIMARY_SUBNET_PREFIX.$GITLAB_OCTET
export BASTION_PTR=$PTR
export GITLAB_PTR=$PTR
export REGISTRY_PTR=$PTR
export CVM_ENDPOINT=$PRIMARY_SUBNET_PREFIX.$CVM_OCTET
export CVM_PASSWORD=$NUTANIX_PASSWORD


# ssh key
# check for existing SSH key variables
if [ -z "${SSH_PUBLIC_GENERIC_KEY}" ]; then
   echo "Error: SSH_PUBLIC_GENERIC_KEY is not set. Aborting."
   exit 1
fi
if [ -z "${SSH_PRIVATE_GENERIC_KEY}" ]; then
   echo "Error: SSH_PRIVATE_GENERIC_KEY is not set. Aborting."
   exit 1
fi

#clean up before generating 
rm -rf ${SSH_KEY_PUBLIC_BASTION_VM_PATH}
rm -rf ${SSH_KEY_PRIVATE_BASTION_VM_PATH}

mkdir -p ${SSH_KEY_PUBLIC_BASTION_VM_PATH}
mkdir -p ${SSH_KEY_PRIVATE_BASTION_VM_PATH}
touch $SSH_KEY_PUBLIC_BASTION_VM_PATH/$SSH_KEY_PUBLIC_BASTION_VM_FILE
touch $SSH_KEY_PRIVATE_BASTION_VM_PATH/$SSH_KEY_PRIVATE_BASTION_VM_FILE
echo "$SSH_PUBLIC_GENERIC_KEY" > "$SSH_KEY_PUBLIC_BASTION_VM_PATH/$SSH_KEY_PUBLIC_BASTION_VM_FILE"
echo "$SSH_PRIVATE_GENERIC_KEY" > "$SSH_KEY_PRIVATE_BASTION_VM_PATH/$SSH_KEY_PRIVATE_BASTION_VM_FILE"


# Define required template files
REQUIRED_TEMPLATES=(
   "terraform.tfvars_template"
   "./packer-ubuntu-nutanix/settings.auto.pkrvars.hcl_template"
   "./packer-ubuntu-nutanix//nutanix-ubuntu.pkr.hcl_template"
   "./userdata.yaml_template"
   "./packer-ubuntu-nutanix/http/user-data_template"
)
# --- Define the files you want to update ---
TARGET_FILES=(
   "./terraform.tfvars"
   "./userdata.yaml"
   "./packer-ubuntu-nutanix/settings.auto.pkrvars.hcl"
   "./packer-ubuntu-nutanix//nutanix-ubuntu.pkr.hcl"
   "./packer-ubuntu-nutanix/http/user-data"
)
# clean up old files if they are there
echo "Cleaning up old target files..."
for target_file in "${TARGET_FILES[@]}"; do
   rm -f "$target_file"
done

# Loop through the array, check existence, and copy
for template_file in "${REQUIRED_TEMPLATES[@]}"; do
   if [ ! -f "$template_file" ]; then
       echo "Error: Required template file is missing: $template_file"
       echo "Aborting."
       exit 1
   else
       # Strip '_template' from the filename to get the exact target path
       target_file="${template_file%_template}"
       
       echo "Copying $template_file to $target_file..."
       cp "$template_file" "$target_file"
       
       # Verification: Ensure the copy was successful
       if [ $? -ne 0 ]; then
           echo "Error: Failed to copy $template_file to $target_file"
           exit 1
       fi
   fi
done

echo "applying variable substitutions to target files..."

for FILE in "${TARGET_FILES[@]}"; do
    if [ -f "$FILE" ]; then
        echo "Updating variables in: $FILE"
        
        sed -e "s|_PRIMARY_SUBNET_NAME_|${PRIMARY_SUBNET_NAME}|g" \
            -e "s|_PE_CLUSTER_NAME_|${PE_CLUSTER_NAME}|g" \
            -e "s|_NUTANIX_PASSWORD_|${NUTANIX_PASSWORD}|g" \
            -e "s|_SECONDARY_SUBNET_NAME_|${SECONDARY_SUBNET_NAME}|g" \
            -e "s|_AD_BIND_PASSWORD_|${AD_BIND_PASSWORD}|g" \
            -e "s|_DHCP_SUBNET_PREFIX_|${DHCP_SUBNET_PREFIX}|g" \
            -e "s|_PC_ENDPOINT_|${PC_ENDPOINT}|g" \
            -e "s|_AD_ENDPOINT_|${AD_ENDPOINT}|g" \
            -e "s|_BASTION_IP_|${BASTION_IP}|g" \
            -e "s|_REGISTRY_IP_|${REGISTRY_IP}|g" \
            -e "s|_GITLAB_IP_|${GITLAB_IP}|g" \
            -e "s|_BASTION_PTR_|${BASTION_PTR}|g" \
            -e "s|_GITLAB_PTR_|${GITLAB_PTR}|g" \
            -e "s|_REGISTRY_PTR_|${REGISTRY_PTR}|g" \
            -e "s|_CVM_ENDPOINT_|${CVM_ENDPOINT}|g" \
            -e "s|_CVM_PASSWORD_|${CVM_PASSWORD}|g" \
            -e "s|_HOSTING_URL_|${HOSTING_URL}|g" \
            -e "s|_NKP_HOSTING_PATH_|${NKP_HOSTING_PATH}|g" \
            -e "s|_AD_USER_|${AD_USER}|g" \
            -e "s|_NUTANIX_USER_|${NUTANIX_USER}|g" \
            -e "s|_CVM_USER_|${CVM_USER}|g" \
            -e "s|_PACKER_VM_SOURCE_IMAGE_|${PACKER_VM_SOURCE_IMAGE}|g" \
            -e "s|_PACKER_NKP_VERSION_FOR_PATH_|${PACKER_NKP_VERSION_FOR_PATH}|g" \
            -e "s|_PACKER_NKP_DOWNLOAD_PATH_|${PACKER_NKP_DOWNLOAD_PATH}|g" \
            -e "s|_VM_USER_PASSWORD_|${VM_USER_PASSWORD}|g" \
            -e "s|_VM_USER_PWD_HASH_|${VM_USER_PWD_HASH}|g" \
            -e "s|_VM_USER_|${VM_USER}|g" \
            -e "s|_DOCKER_USER_|${DOCKER_USER}|g" \
            -e "s|_DOCKERIO_TOKEN_|${DOCKERIO_TOKEN}|g" \
            -e "s|_DOCKERIO_URL_|${DOCKERIO_URL}|g" \
            -e "s|_PRIVATE_REGISTRY_INSTALLER_BUNDLE_|${PRIVATE_REGISTRY_INSTALLER_BUNDLE}|g" \
            -e "s|_PRIVATE_REGISTRY_INSTALLER_DOWNLOAD_URL_|${PRIVATE_REGISTRY_INSTALLER_DOWNLOAD_URL}|g" \
            -e "s|_PRIVATE_REGISTRY_URL_|${PRIVATE_REGISTRY_URL}|g" \
            -e "s|_PRIVATE_REGISTRY_USER_|${PRIVATE_REGISTRY_USER}|g" \
            -e "s|_PRIVATE_REGISTRY_TOKEN_|${PRIVATE_REGISTRY_TOKEN}|g" \
            -e "s|_PRIVATE_REGISTRY_NAME_|${PRIVATE_REGISTRY_NAME}|g" \
            -e "s|_NKP_VERSION_BUILD_|${NKP_VERSION_BUILD}|g" \
            -e "s|_NKP_VERSION_PATCH_|${NKP_VERSION_PATCH}|g" \
            -e "s|_SSH_KEY_PRIVATE_REGISTRY_VM_FILE_|${SSH_KEY_PRIVATE_REGISTRY_VM_FILE}|g" \
            -e "s|_SSH_KEY_PRIVATE_REGISTRY_VM_PATH_|${SSH_KEY_PRIVATE_REGISTRY_VM_PATH}|g" \
            -e "s|_SSH_KEY_PUBLIC_REGISTRY_VM_FILE_|${SSH_KEY_PUBLIC_REGISTRY_VM_FILE}|g" \
            -e "s|_SSH_KEY_PUBLIC_REGISTRY_VM_PATH_|${SSH_KEY_PUBLIC_REGISTRY_VM_PATH}|g" \
            -e "s|_TLS_KEY_PRIVATE_REGISTRY_VM_FILE_|${TLS_KEY_PRIVATE_REGISTRY_VM_FILE}|g" \
            -e "s|_TLS_KEY_PRIVATE_REGISTRY_VM_PATH_|${TLS_KEY_PRIVATE_REGISTRY_VM_PATH}|g" \
            -e "s|_TLS_KEY_PUBLIC_REGISTRY_VM_FILE_|${TLS_KEY_PUBLIC_REGISTRY_VM_FILE}|g" \
            -e "s|_TLS_KEY_PUBLIC_REGISTRY_VM_PATH_|${TLS_KEY_PUBLIC_REGISTRY_VM_PATH}|g" \
            -e "s|_SSH_KEY_PRIVATE_BASTION_VM_FILE_|${SSH_KEY_PRIVATE_BASTION_VM_FILE}|g" \
            -e "s|_SSH_KEY_PRIVATE_BASTION_VM_PATH_|${SSH_KEY_PRIVATE_BASTION_VM_PATH}|g" \
            -e "s|_SSH_KEY_PUBLIC_BASTION_VM_FILE_|${SSH_KEY_PUBLIC_BASTION_VM_FILE}|g" \
            -e "s|_SSH_KEY_PUBLIC_BASTION_VM_PATH_|${SSH_KEY_PUBLIC_BASTION_VM_PATH}|g" \
            -e "s|_TLS_KEY_PRIVATE_BASTION_VM_FILE_|${TLS_KEY_PRIVATE_BASTION_VM_FILE}|g" \
            -e "s|_TLS_KEY_PRIVATE_BASTION_VM_PATH_|${TLS_KEY_PRIVATE_BASTION_VM_PATH}|g" \
            -e "s|_TLS_KEY_PUBLIC_BASTION_VM_FILE_|${TLS_KEY_PUBLIC_BASTION_VM_FILE}|g" \
            -e "s|_TLS_KEY_PUBLIC_BASTION_VM_PATH_|${TLS_KEY_PUBLIC_BASTION_VM_PATH}|g" \
            -e "s|_SSH_KEY_PRIVATE_GITLAB_VM_FILE_|${SSH_KEY_PRIVATE_GITLAB_VM_FILE}|g" \
            -e "s|_SSH_KEY_PRIVATE_GITLAB_VM_PATH_|${SSH_KEY_PRIVATE_GITLAB_VM_PATH}|g" \
            -e "s|_SSH_KEY_PUBLIC_GITLAB_VM_FILE_|${SSH_KEY_PUBLIC_GITLAB_VM_FILE}|g" \
            -e "s|_SSH_KEY_PUBLIC_GITLAB_VM_PATH_|${SSH_KEY_PUBLIC_GITLAB_VM_PATH}|g" \
            -e "s|_TLS_KEY_PRIVATE_GITLAB_VM_FILE_|${TLS_KEY_PRIVATE_GITLAB_VM_FILE}|g" \
            -e "s|_TLS_KEY_PRIVATE_GITLAB_VM_PATH_|${TLS_KEY_PRIVATE_GITLAB_VM_PATH}|g" \
            -e "s|_TLS_KEY_PUBLIC_GITLAB_VM_FILE_|${TLS_KEY_PUBLIC_GITLAB_VM_FILE}|g" \
            -e "s|_TLS_KEY_PUBLIC_GITLAB_VM_PATH_|${TLS_KEY_PUBLIC_GITLAB_VM_PATH}|g" \
            -e "s|_SSH_KEY_PUBLIC_|${SSH_KEY_PUBLIC}|g" \
            -e "s|_SSH_PUBLIC_GENERIC_KEY_|${SSH_PUBLIC_GENERIC_KEY}|g" \
            -e "s|_PACKER_USER_DATA_ROOT_PASSWD_|${PACKER_USER_DATA_ROOT_PASSWD}|g" \
            -e "s|_PACKER_USER_DATA_ALLOW_SSH_PW_AUTH_|${PACKER_USER_DATA_ALLOW_SSH_PW_AUTH}|g" \
            -e "s|_PACKER_VM_SOURCE_IMAGE_|${PACKER_VM_SOURCE_IMAGE}|g" \
            -e "s|_NKP_INSTALLATION_GIT_REPO_BRANCH_|${NKP_INSTALLATION_GIT_REPO_BRANCH}|g" \
            -e "s|_NKP_INSTALLATION_GIT_REPO_URL_|${NKP_INSTALLATION_GIT_REPO_URL}|g" \
            -e "s|_NKP_INSTALLATION_GIT_REPO_DIR_|${NKP_INSTALLATION_GIT_REPO_DIR}|g" \
            -e "s|_NKP_BASTION_WORKING_DIR_|${NKP_BASTION_WORKING_DIR}|g" \
            -e "s|_NKP_BASTION_BUNDLE_NAME_|${NKP_BASTION_BUNDLE_NAME}|g" \
            -e "s|_NKP_BASTION_BUNDLE_EXTRACTION_DIR_|${NKP_BASTION_BUNDLE_EXTRACTION_DIR}|g" \
            -e "s|_INSTALL_NKP_MGMT_CLUSTER_|${INSTALL_NKP_MGMT_CLUSTER}|g" \
            -e "s|_NKP_MGMT_CLUSTER_NAME_|${NKP_MGMT_CLUSTER_NAME}|g" \
            -e "s|_DEPLOY_NAI_|${DEPLOY_NAI}|g" \
            -e "s|_DEPLOY_GITLAB_|${DEPLOY_GITLAB}|g" \
            -e "s|_NKP_LICENSE_JWT_|${NKP_LICENSE_JWT}|g" \
            -e "s|_NKP_WORKSPACE_NAME_|${NKP_WORKSPACE_NAME}|g" \
            -e "s|_NKP_WORKSPACE_NAMESPACE_|${NKP_WORKSPACE_NAMESPACE}|g" \
            -e "s|_NKP_UBUNTU_IMAGE_NAME_|${NKP_UBUNTU_IMAGE_NAME}|g" \
            -e "s|_NKP_UBUNTU_IMAGE_DOWNLOAD_URL_PATH_|${NKP_UBUNTU_IMAGE_DOWNLOAD_URL_PATH}|g" \
            -e "s|_OS_DOWNLOAD_PATH_|${OS_DOWNLOAD_PATH}|g" \
            -e "s|_NAI_BUNDLE_DOWNLOAD_URL_|${NAI_BUNDLE_DOWNLOAD_URL}|g" \
            -e "s|_NAI_BUNDLE_NAME_|${NAI_BUNDLE_NAME}|g" \
            -e "s|_NAI_HELM_CHART_NAME_|${NAI_HELM_CHART_NAME}|g" \
            -e "s|_NAI_WORKER_NODE_COUNT_|${NAI_WORKER_NODE_COUNT}|g" \
            -e "s|_NAI_VCPU_COUNT_|${NAI_VCPU_COUNT}|g" \
            -e "s|_NAI_MEMORY_SIZE_|${NAI_MEMORY_SIZE}|g" \
            -e "s|_PROJECT_NAME_|${PROJECT_NAME}|g" \
            -e "s|_SELF_SERVICE_STORAGE_CONTAINER_NAME_|${SELF_SERVICE_STORAGE_CONTAINER_NAME}|g" \
             "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
    else
        echo "Warning: File $FILE not found, skipping."
    fi
done


export SSH_KEY_PRIVATE_REGISTRY_VM_FILE="id_ed25519"
export SSH_KEY_PRIVATE_REGISTRY_VM_PATH="keys/bastion/ssh"
export SSH_KEY_PUBLIC_REGISTRY_VM_FILE="id_ed25519.pub"
export SSH_KEY_PUBLIC_REGISTRY_VM_PATH="keys/bastion/ssh"

export TLS_KEY_PRIVATE_REGISTRY_VM_FILE="registry-private.key"
export TLS_KEY_PRIVATE_REGISTRY_VM_PATH="keys/registry/tls"
export TLS_KEY_PUBLIC_REGISTRY_VM_FILE="registry-server.crt"
export TLS_KEY_PUBLIC_REGISTRY_VM_PATH="keys/registry/tls"

echo "Replacements complete!"

echo "Clearing out old state or workspace..."
terraform init
terraform fmt -recursive
terraform validate

if [ "$DESTRUCTIVE_MODE" = true ]; then
    echo "Destructive mode is enabled. Destroying existing resources..."
   terraform workspace select default
   # || true ensures the script doesn't crash if the workspace doesn't exist yet
   terraform workspace delete -force $PE_CLUSTER_NAME || true 
   terraform workspace new $PE_CLUSTER_NAME

   # Remove old ssh key gracefully
   ssh-keygen -R $BASTION_IP 2>/dev/null || true
else
    echo "Destructive mode is disabled. Skipping resource cleanup."
fi

echo "Running terraform plan..."
# If plan fails, the script will exit here because of 'set -e'
terraform plan -out=plans/$PE_CLUSTER_NAME

if [ "$APPLY_TERRAFORM" = true ]; then
   echo "Running terraform apply..."
    TF_LOG=DEBUG TF_LOG_PATH="terraform.log" terraform apply -auto-approve plans/$PE_CLUSTER_NAME
else
    echo "APPLY_TERRAFORM is set to false. Skipping terraform apply."
fi
# TF_LOG=DEBUG TF_LOG_PATH="terraform.log" terraform apply -auto-approve plans/$PE_CLUSTER_NAME
