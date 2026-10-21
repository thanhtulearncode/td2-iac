# TD2 - Industrialiser K3s avec Terraform, Ansible et Helm

Pipeline IaC : Terraform (VM OpenStack) -> Ansible (K3s) -> Helm (frontend, backend, PostgreSQL).

## Utilisation
1. `cd terraform && cp example.tfvars terraform.tfvars` (puis éditer `login`)
2. `terraform init && terraform apply`
3. `terraform output -raw ansible_inventory > ../ansible/inventory.ini`
4. `cd ../ansible && ansible-playbook playbook.yml`
5. `./tunnel.sh` (terminal dédié), puis `export KUBECONFIG=$PWD/kubeconfig`
6. `kubectl create namespace td2`, puis `helm install <chart> ./helm/<chart> -n td2`

## Choix
- data sources pour le socle partagé (asl-net, asl-key, image)
- `config_drive = true` : metadata service injoignable sur ce DevStack
- tunnel SSH vers l'API K3s (6443 non ouvert dans le security group)
- secrets en clair dans values.yaml : assumé (labo), traité au TD3
