# TD2 - Industrialisation de K3s avec Terraform, Ansible et Helm

Ce TD provisionne une VM sur OpenStack, y installe K3s et déploie une application composée d'un frontend Nginx, d'une API Python et d'une base PostgreSQL.

## Stack technique

- **Terraform** : VM Ubuntu, groupe de sécurité et IP flottante OpenStack.
- **Ansible** : prérequis système, installation de K3s et configuration du kubeconfig.
- **K3s et Helm** : cluster Kubernetes et déploiement des charts.
- **Application** : frontend Nginx avec Ingress Traefik, API Python et PostgreSQL avec stockage persistant.

## Structure du dépôt

```text
.
├── terraform/  # Infrastructure OpenStack
├── ansible/    # Playbook et rôles K3s
└── helm/       # Charts postgres, backend et frontend
```

## Déploiement

Les étapes ci-dessous supposent que le dépôt se trouve dans `~/td2` sur l'environnement Linux où Terraform, Ansible, Helm, kubectl et sshpass sont installés.

### 1. Provisionner l'infrastructure

Copier le fichier d'exemple vers le fichier de variables principal, puis renseigner votre login dans `terraform.tfvars` :

```bash
cd ~/td2/terraform
cp example.tfvars terraform.tfvars
# Modifier terraform.tfvars et remplacer "votre_login" par votre login
terraform init
terraform apply
terraform output -raw ansible_inventory > ../ansible/inventory.ini
```

### 2. Installer et configurer K3s

```bash
cd ~/td2/ansible
ansible-playbook playbook.yml
```

### 3. Ouvrir le tunnel SSH vers l'API Kubernetes

Dans un terminal, lancer le tunnel et le laisser actif :

```bash
cd ~/td2/ansible
./tunnel.sh
```

Dans un autre terminal, configurer l'accès au cluster :

```bash
export KUBECONFIG="$HOME/td2/ansible/kubeconfig"
```

### 4. Déployer l'application

```bash
cd ~/td2
kubectl create namespace td2 --dry-run=client -o yaml | kubectl apply -f -
helm install postgres ./helm/postgres --namespace td2
helm install backend ./helm/backend --namespace td2
helm install frontend ./helm/frontend --namespace td2
```

## Vérification

### Validation bout en bout

Depuis l'hôte DevStack, avec le tunnel SSH actif et `KUBECONFIG` configuré :

```bash
cd ~/td2/terraform
export FIP=$(terraform output -raw floating_ip)
echo "URL : http://$FIP"

# 1. Les trois releases Helm doivent être en état deployed
helm list -n td2

# 2. Vérifier les pods, services, StatefulSet, Ingress et PVC
kubectl -n td2 get pods,svc,statefulset,ingress,pvc

# 3. Vérifier les endpoints des services
kubectl -n td2 get endpoints

# 4. Le frontend doit répondre HTTP 200
curl -I "http://$FIP" | head -3

# 5. Vérifier la répartition des requêtes entre les deux pods frontend
for i in $(seq 1 6); do
  curl -sI "http://$FIP" | grep -i '^X-Pod-Name'
done

# 6. Vérifier la réponse JSON de l'API (pod backend et trois éléments)
curl -s "http://$FIP/api/items" | python3 -m json.tool
```

Résultats attendus : trois releases Helm `deployed`, cinq pods `Running`, l'Ingress frontend présent, et deux adresses IP chacune pour les endpoints frontend et backend. La requête HTTP renvoie `200 OK`, l'en-tête `X-Pod-Name` montre les deux pods frontend et l'API renvoie un JSON contenant le nom du pod backend et les trois éléments.

### Validation visuelle

Ouvrir `http://<IP_FLOTTANTE>` dans un navigateur : les noms des pods frontend et backend doivent apparaître et s'actualiser, le tableau doit afficher les trois éléments et le badge « En ligne » doit être vert.
