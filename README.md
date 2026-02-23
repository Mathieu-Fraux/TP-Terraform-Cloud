# TP-Terraform-Cloud ☁️

Ce dépôt contient le code Terraform permettant de déployer une infrastructure hautement disponible sur Microsoft Azure. L'objectif de ce TP est de provisionner un réseau, des règles de sécurité, deux machines virtuelles (avec Nginx) et un Load Balancer.

---

## 🛠️ 1. Prérequis et Installation

Pour exécuter ce projet, deux outils sont nécessaires :

### Terraform 

Téléchargement web classique (nécessite de configurer le PATH de Windows), ou via ligne de commande  :
```bash
winget install Hashicorp.Terraform
```
![](capture/telechargemant%20terraform.png)


### Azure CLI 

Téléchargement depuis le site officiel de Microsoft, ou via ligne de commande :
```bash
winget install Microsoft.AzureCLI
```
![](capture/telechargemant%20azure%20cli.png)

---

## 🔐 2. Authentification et Sécurité

Avant de lancer les scripts, il est nécessaire de se connecter à son compte Azure via la commande :
```bash
az login
```

**Gestion des secrets :** Pour éviter d'exposer mon id publiquement sur GitHub, j'ai mis en place une stratégie de sécurité. Après plusieurs essais (notamment en tentant de masquer le fichier `provider.tf` entier), j'ai opté pour l'utilisation stricte du fichier `.gitignore` et d'un fichier `.tfvars` local. Ainsi, les identifiants locaux ne sont jamais poussés sur le dépôt distant.

---

## 🏗️ 3. Architecture et Déploiement

Le projet a été structuré selon les bonnes pratiques Terraform (séparation en plusieurs fichiers : `main.tf`, `variables.tf`, `version.tf`, `provider.tf` et `outputs.tf`).

Voici l'ordre de construction de l'infrastructure :

1. **Réseau de base :** Création du Resource Group, du Virtual Network  et du Subnet.
2. **Sécurité :** Mise en place du Network Security Group pour autoriser les ports 22 (SSH) et 80 (HTTP) et bloquer le reste.
3. **Compute :** Déploiement de 2 VMs Linux. L'installation du serveur web Nginx est automatisée au démarrage via l'attribut `custom_data`.
4. **Disponibilité :** Configuration d'un Load Balancer public pour répartir la charge entre les deux VMs (avec une Sonde HTTP).

---

## 🐛 4. Difficultés rencontrées et Résolutions

Lors de ce TP, j'ai dû procéder à plusieurs itérations (`apply` / `destroy`) suite à quelques obstacles :

- **Problème de capacité régionale :** Le déploiement dans la région `France Central` échouait par manque de ressources disponibles côté Azure pour les comptes étudiants. J'ai résolu ce problème en modifiant ma variable vers `Switzerland North` (Suisse du Nord).

- **Désynchronisation de l'API Azure :** Lors d'un déploiement, le Provider Terraform a planté en raison d'un délai de réponse d'Azure (différentiel de temps) sur la création des ressources (notamment un disque bloqué). Un nettoyage propre (`terraform destroy` ) et une relance ont permis de corriger ce bug de synchronisation.

---

## 📸 5. Preuves de fonctionnement (Livrables)

[](/capture/)

### 1. Planification réussie — `terraform plan`
Le plan indique bien la création de toutes les ressources nécessaires (16 au total).
![](/capture/capture%20terraform%20plan.png)

### 2. Déploiement réussi — `terraform apply`
L'infrastructure a été entièrement créée sur Azure.
![](/capture/Capture%20terraform%20apply.png)

### 3. Accès au serveur web via le Load Balancer
L'adresse IP publique du Load Balancer distribue bien le trafic (les deux VMs répondent alternativement).
![](/capture/Capture%20VM1.png)
![](capture/Capture%20VM2.png)

### 4. Nettoyage de l'infrastructure — `terraform destroy`
Suppression complète pour éviter la consommation de crédits inutiles.
![](capture/Capture%20terraform%20destroy.png)