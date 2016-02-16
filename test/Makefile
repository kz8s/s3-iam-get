AWS:=`which aws`
TF:=`which terraform`

BUCKET=`terraform output bucket`
IP=`terraform output ip`
PEM="${BUCKET}.pem"

REGION:=us-west-1

terraform.tfvars: ; ./init ${REGION}

apply: terraform.tfvars ; ${TF} apply

destroy:
	-./destroy-key ${REGION} ${BUCKET}
	-${TF} destroy -force
	-rm -f terraform.tfvars

init: terraform.tfvars

ssh: ; ssh -i ${PEM} core@${IP}

test:
	ssh-keyscan -H ${IP} >> ~/.ssh/known_hosts
	ssh -i ${PEM} core@${IP} "grep -Fx test <test"
	ssh -i ${PEM} core@${IP} "grep -Fx deep <deep"

.PHONY: apply destroy init ssh test
