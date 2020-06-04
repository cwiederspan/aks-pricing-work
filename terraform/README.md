# Setup Cluster

## Setting Up

```bash

# Use local storage
terraform init

```

## Execution

```bash

# Run the plan to see the changes
terraform plan \
-var 'name_prefix=cdw' \
-var 'name_base=pricingtest' \
-var 'name_suffix=20200603' \
-var 'aks_version=1.16.9' \
-var 'location=westus2' \
-var 'node_vm_sku=Standard_D8s_v3' \
--var-file=secrets.tfvars

# Apply the script with the specified variable values
terraform apply \
-var 'name_prefix=cdw' \
-var 'name_base=pricingtest' \
-var 'name_suffix=20200603' \
-var 'aks_version=1.16.9' \
-var 'location=westus2' \
-var 'node_vm_sku=Standard_D8s_v3' \
--var-file=secrets.tfvars

# Apply the script with the specified variable values
terraform destroy \
-var 'name_prefix=cdw' \
-var 'name_base=pricingtest' \
-var 'name_suffix=20200603' \
-var 'aks_version=1.16.9' \
-var 'location=westus2' \
-var 'node_vm_sku=Standard_D8s_v3' \
--var-file=secrets.tfvars

```

## Getting Info

```bash

az aks get-credentials --overwrite-existing -g cdw-pricingtest-20200603 -n cdw-pricingtest-20200603

k describe node aks-lnx000-39615605-vmss000000

k describe node akswin001000000

```
