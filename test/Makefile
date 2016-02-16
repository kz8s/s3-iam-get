AWS:=`which aws`
TF:=`which terraform`

REGION:="us-west-1"

terraform.tfvars:
	./init "${REGION}"

apply: terraform.tfvars
	TF_LOG=TRACE ${TF} apply

clean: ; -rm -f terraform.tfvars

destroy:
	./destroy-key ${REGION} `terraform output bucket`
	terraform destroy -force
	rm -f terraform.tfvars

init: terraform.tfvars

.PHONY: apply clean destroy init
