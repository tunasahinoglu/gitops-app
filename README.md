# gitops-app

A Java web application and the CI pipeline that builds it. On every push to
`main`, GitHub Actions builds the image, scans it, pushes it to ECR and then
commits the new image tag to a separate config repo, which ArgoCD picks up
and deploys.

Part of a three repo GitOps project:
- **gitops-app** (this repo) - the application and its CI pipeline
- [gitops-config](https://github.com/tunasahinoglu/gitops-config) - Helm
  chart and ArgoCD manifests, the repo ArgoCD watches
- [gitops-infra](https://github.com/tunasahinoglu/gitops-infra) - Terraform
  for the VPC and EKS cluster

The application is a multi tier Java app (Tomcat, MySQL, RabbitMQ, Memcached)
based on an open source reference project. The focus here is the pipeline, not
the app code.

## CI pipeline

Two paths, depending on the event:

**On pull request** - build, unit tests, Checkstyle, SonarQube scan and a
quality gate that blocks the PR if it fails.

**On push to `main`:**

1. Build two images: the app (multi stage, compiled from this repo's source)
   and the database (MySQL seeded with the app schema).
2. Scan both with Trivy, failing on fixable HIGH/CRITICAL vulnerabilities.
3. Push to ECR, tagged with the short commit SHA.
4. Clone the config repo, update the image names and tags in the Helm values
   with `yq` and commit.

Step 4 is what makes this GitOps rather than a direct deploy: CI never talks
to the cluster. It only changes what's declared in Git and ArgoCD reconciles
the cluster to match.

## Configuration

No credentials are committed. `application.properties` reads database,
RabbitMQ and admin credentials from environment variables, which are
supplied as Kubernetes secrets at deploy time.

The CI workflow expects these repository secrets:

| Secret | Purpose |
|--------|---------|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Pushing to ECR |
| `SONAR_TOKEN` | SonarQube authentication |
| `GITOPS_PAT` | Write access to the config repo |
| `HELM_REPO_USER` | GitHub username for the config repo clone |

And these repository variables: `AWS_REGION`, `ECR_REPOSITORY`,
`ECR_DB_REPOSITORY`, `HELM_REPO_NAME`, `SONAR_HOST_URL`.
