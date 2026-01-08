# EKS + Karpenter Terraform Project

This repository contains Terraform code to provision an Amazon EKS cluster with Karpenter auto-scaling.

## Prerequisites

Ensure you have the following tools installed:

*   [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (configured with credentials)
*   [Terraform](https://developer.hashicorp.com/terraform/install) (v1.0+)
*   [kubectl](https://kubernetes.io/docs/tasks/tools/)
*   [helm](https://helm.sh/docs/intro/install/)

## Deployment Steps

### 1. Initialize Terraform
Initialize the project to download providers and modules.
```bash
terraform init
```

### 2. Apply Configuration
Create the infrastructure (VPC, EKS, IAM Roles, Karpenter).
```bash
terraform apply
```
Review the plan and type `yes` to confirm.

### 3. Configure kubectl
Update your kubeconfig to interact with the new cluster.
```bash
aws eks update-kubeconfig --region eu-central-1 --name EKS-Cluster
```

## Verification

### Check Nodes
Verify that the initial system nodes are ready.
```bash
kubectl get nodes
```

### Check Karpenter Status
Ensure the Karpenter controller is running.
```bash
kubectl get pods -n karpenter
```
Check Karpenter logs to ensure it's listening.
```bash
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter
```

### Test Auto-scaling
Deploy a sample application that requests resources, triggering Karpenter to provision new nodes.

1.  **Apply the inflate deployment**:
    ```bash
    kubectl apply -f inflate.yaml
    ```
    This deployment has 0 replicas initially.

2.  **Scale it up**:
    ```bash
    kubectl scale deployment inflate --replicas=3
    ```
    Each pod requests 1 CPU. Since the existing node cannot hold 3 pods (plus system pods), Karpenter will provision new generic Spot nodes (arm64/amd64 as configured).

3.  **Watch nodes provision**:
    ```bash
    kubectl get nodes -w
    ```
    You should see new nodes being added by Karpenter to handle the pending pods.

4.  **Cleanup test**:
    ```bash
    kubectl delete deployment inflate
    ```

## Cleanup

To tear down all infrastructure:
```bash
terraform destroy
```
