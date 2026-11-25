# CI/CD Lab 1: GitHub Actions + Terraform + Azure

Static website on an Azure Storage Account, delivered by a pipeline.

## Layout
```
.github/workflows/lab1.yml     CI (fmt, validate), plan on PR, approval + apply + site upload on main
.github/workflows/destroy.yml  Manual clean-up (needs approval)
infra/                         Terraform (main.tf, variables.tf, outputs.tf)
site/                          The "app": index.html and 404.html
bootstrap/bootstrap.ps1        One-time setup: state storage, OIDC identity, roles
```

## Quick start
1. Create a PUBLIC GitHub repo (needed for environment approvals on the free plan) and clone it.
2. Copy these files into it.
3. `az login`, then `.\bootstrap\bootstrap.ps1 -GitHubUser <you> -GitHubRepo <repo>`
4. In GitHub: add the 5 printed values as repository Variables, and create Environment `production` with yourself as Required reviewer.
5. `git add . ; git commit -m "Initial lab 1" ; git push origin main`
6. Actions tab: approve the deployment, then open the site URL printed in the last step.

## Local checks (no Azure needed)
```
cd infra
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

## Clean up
Run the `lab1-destroy` workflow, then optionally `az group delete -n rg-tfstate-lab --yes`.
