AWS:=`which aws`
TF:=`which terraform`

BUCKET=`terraform output bucket`
IP="`terraform output ip`"
PEM="`terraform output bucket`.pem"

REGION:="us-west-1"

terraform.tfvars:
	./init "${REGION}"

apply: terraform.tfvars ; ${TF} apply

destroy:
	./destroy-key ${REGION} `terraform output bucket`
	${TF} destroy -force
	rm -f terraform.tfvars

init: terraform.tfvars

ssh: ; ssh -i ${PEM} core@${IP}

.PHONY: apply destroy init ssh
