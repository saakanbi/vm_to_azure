
# VM → Azure Cloud Modernization (Terraform + Azure DevOps + AKS)

This hands-on project shows how to migrate a VM-based Java web app to **Azure AKS** with **Terraform** and **Azure DevOps (YAML pipelines)**.

## What it does
- Provisions Azure infra with Terraform: Resource Group, ACR, AKS
- Builds a Java app with Maven + JUnit
- Builds & pushes a Docker image to **ACR**
- Deploys to **AKS** using Kubernetes manifests
- Monitors with Azure Monitor / Container Insights (enable on AKS)

## Quick Start

### 1) Terraform (provision Azure infra)
Edit values in `terraform/variables.tf` or pass via `-var` flags.

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

Outputs:
- AKS name / RG
- ACR name

### 2) Build app & push image (locally or via Azure DevOps)
Local example:
```bash
cd app
mvn -q -DskipTests=false clean package
IMAGE_TAG=local-$(date +%s)
az acr login -n <YOUR_ACR_NAME>
docker build -t <YOUR_ACR_NAME>.azurecr.io/vm2cloud-demo:${IMAGE_TAG} .
docker push <YOUR_ACR_NAME>.azurecr.io/vm2cloud-demo:${IMAGE_TAG}
```

### 3) Deploy to AKS
```bash
az aks get-credentials -g <RG> -n <AKS_NAME> --overwrite-existing
sed -i "s|__ACR__|<YOUR_ACR_NAME>|g" k8s/deployment.yaml
sed -i "s|__TAG__|${IMAGE_TAG}|g" k8s/deployment.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl rollout status deploy/vm2cloud-demo -n default --timeout=180s
```

### 4) Azure DevOps Pipeline
Use `ci/azure-pipelines.yml`. Create a Service Connection to Azure and a connection to your ACR.
Pipeline stages: **Build → Scan (Sonar optional) → Image → Deploy**.

---

## Folder Structure
```
vm-to-azure-aks/
├─ terraform/               # IaC (AKS, ACR, RG)
├─ app/                     # Java Spring Boot app + Maven
├─ k8s/                     # Kubernetes manifests (Deployment, Service)
└─ ci/azure-pipelines.yml   # Azure DevOps pipeline
```

## Notes
- Enable **Container Insights** when creating AKS (built into template).
- For App Insights, add the SDK to the app and a connection string.
- For prod, add namespaces, HPA, PodDisruptionBudgets, network policies, Key Vault, and approvals.
