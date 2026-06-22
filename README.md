Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Deploying to AWS

This app deploys via [Kamal](https://kamalmanual.com) to a single EC2 instance, with Postgres running as a Kamal accessory container on the same box. No RDS, no ECS — just one box and Docker, matching the `config/deploy.yml` already in this repo.

### 1. AWS setup (console)

1. Create an IAM user (not root) with EC2 + ECR permissions; generate access keys for the AWS CLI.
2. Launch an EC2 instance — Ubuntu 24.04, `t3.small`/`t4g.small` is enough — with a security group allowing inbound 22 (your IP only), 80, 443.
3. Allocate an Elastic IP and associate it with the instance.
4. Add your SSH public key at launch (Kamal connects over SSH to provision Docker and deploy).
5. Create an ECR repository for the `present` image.
6. (Optional) Point a domain at the Elastic IP via Route 53 or your existing registrar.

### 2. Repo config

Fill in the `TODO` placeholders in `config/deploy.yml`:

- `servers.web` → your Elastic IP
- `accessories.postgres.host` → the same Elastic IP
- `registry.server` → your ECR repository URI (`<account-id>.dkr.ecr.<region>.amazonaws.com`)

Set `proxy.ssl.host` to your domain once you have one (deploy to the bare IP first if not).

Set `APP_HOST` (used for mailer links, e.g. Devise password resets) to your domain or IP via `config/deploy.yml`'s `env.clear` once known.

### 3. Secrets

Before running any `bin/kamal` command, export in your shell:

```bash
export POSTGRES_PASSWORD=<a strong password>
```

`.kamal/secrets` reads `RAILS_MASTER_KEY` from `config/master.key` and `POSTGRES_PASSWORD`/`PRESENT_DATABASE_PASSWORD` from this env var automatically — neither is ever committed.

For ECR registry auth, also export `KAMAL_REGISTRY_PASSWORD` to an ECR auth token (`aws ecr get-login-password`).

### 4. Deploy

```bash
bin/kamal setup   # first time: provisions Docker on the server, builds/pushes, starts containers
bin/kamal deploy  # every deploy after that
```

Verify with `curl http://<elastic-ip>/up` (expect `200`), then sign up as the first real admin user through the normal Devise flow.
