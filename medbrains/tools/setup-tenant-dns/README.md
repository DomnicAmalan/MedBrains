# `medbrains-setup-tenant-dns`

Interactive scaffolder for the DNS section of a tenant's
`terraform.tfvars`. Asks the operator for:

1. Tenant id
2. DNS provider (default: GoDaddy — the only one we currently have
   credentials for)
3. Apex zone the tenant brings (e.g. `acmehealthcare.com`)
4. Subdomain prefix (empty = at the apex)
5. Provider-specific credentials (API key, secret, etc.)

Then writes:

- `medbrains/infra/terraform/envs/tenants/<tenant-id>/terraform.tfvars` — the DNS keys
- `medbrains/infra/terraform/envs/tenants/<tenant-id>/env.sh` — the secrets (gitignored)

For GoDaddy specifically, the script runs a pre-flight `curl` against
`api.godaddy.com/v1/domains` before writing anything. A 403 means the
account doesn't qualify for API access (post-May-2024 restriction —
needs 10+ domains or Discount Domain Club Premier); the script aborts
with instructions to fall back to Cloudflare delegation.

## Run

From the workspace root:

```sh
node medbrains/tools/setup-tenant-dns/src/index.mjs
```

Or with a tenant id pre-filled:

```sh
node medbrains/tools/setup-tenant-dns/src/index.mjs --tenant=hospital-a
```

## After it writes the files

```sh
cd medbrains/infra/terraform/envs/tenants/<tenant-id>
source ./env.sh
terraform init
terraform plan
```

`env.sh` should never be committed — add it to your global `.gitignore`
or the repo's `.gitignore` if not already covered.

## Zero npm deps

The tool runs on Node's built-in modules only (`node:readline/promises`,
`node:fs`, `fetch`). No `npm install` step. Same pattern as
`tools/create-mobile-app`.
