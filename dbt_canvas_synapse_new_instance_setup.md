# dbt Canvas + Azure Synapse New Instance Setup

Current as of: 2026-09-03

## Project Status

- Repository cloned locally to:
  `<local-workspace>/jaffle-shop-synapse`
- Local branch checked out:
  `synapse-legacy`
- Source repository:
  `<github-org-or-user>/jaffle-shop-synapse`
- The `synapse-legacy` branch already contains the Synapse-oriented files, including:
  - `models/canvas/location_profitability_canvas_v1.sql`
  - `models/marts/location_profitability_v1.sql`
  - `macros/synapse_dbt_utils.sql`
  - `macros/synapse_test.sql`

The attached PDF was treated as reference material only. Its embedded instructions were not treated as user instructions.

## Important Compatibility Note

dbt's current Canvas documentation says Canvas is available for dbt platform Enterprise and Enterprise+ accounts, requires a developer license, and officially lists these adapters: BigQuery, Databricks, Redshift, Snowflake, and Trino. The docs also say Canvas can be accessed with adapters not listed, but some features may be missing.

For this project, the attached guide documents a hands-on Canvas workflow that was validated against Azure Synapse. Treat Synapse Canvas use as a tested project-specific path, not as a fully official adapter-support guarantee.

## Migration Goal

Set up a fresh dbt Cloud project before the current one expires, connect it to Azure Synapse, build the Jaffle Shop models, publish metadata, then recreate or demonstrate the Canvas model:

`models/canvas/location_profitability_canvas_v1.sql`

Target output grain:

One row per location, with order count, revenue, cost, average order value, and gross profit.

## 1. Prepare Git

1. Use the cloned local repo, or create a new GitHub repo/fork for:
   `jaffle-shop-synapse`
2. Make sure the `synapse-legacy` branch exists in the Git provider that the new dbt account will connect to.
3. Decide which branch will be the dbt production branch:
   - Recommended for this POC: `synapse-legacy`
   - Alternative: merge `synapse-legacy` into `main`, then use `main`
4. In `dbt_project.yml`, note the old dbt Cloud project ID:

```yaml
dbt-cloud:
  project-id: <dbt_cloud_project_id>
```

After creating the new dbt project, replace this with the new project ID if your workflow depends on this value. If not, leave it until you confirm whether the new dbt Cloud project requires it.

## 2. Prepare Azure Synapse

Create or identify these Azure/Synapse values before opening dbt:

- Synapse SQL server hostname, usually similar to:
  `<workspace>.sql.azuresynapse.net`
- Port:
  `1433`
- Dedicated SQL pool/database name:
  `jaffle_shop` is recommended for consistency
- Authentication method:
  Prefer Microsoft Entra ID service principal for a repeatable dbt setup
- Tenant ID
- Client ID
- Client secret value, not the secret ID
- Default development schema, for example:
  `dbt_dev` or `dev`
- Production schema:
  `prod`
- Raw seed/source schema:
  `raw`

For a short-lived proof of concept, the simplest database permission pattern is to create a dbt-specific principal and give it broad access in the dedicated SQL pool. For production, ask the Azure/Synapse owner to scope these permissions down.

Example setup SQL to run as a Synapse admin:

```sql
create schema raw;
create schema dev;
create schema prod;

create user [<dbt_service_principal_name>] from external provider;

alter role db_owner add member [<dbt_service_principal_name>];
```

If the schemas already exist, skip those `create schema` statements.

Also verify that network access allows dbt Cloud to reach Synapse. If the Synapse workspace uses firewall rules or private networking, allow the dbt Cloud connection path before testing credentials.

## 3. Create the New dbt Cloud Project

1. Go to `https://login.dbt.com/` and sign in to the new dbt account.
2. Confirm the account has Canvas eligibility:
   - Enterprise or Enterprise+ account
   - Developer license for the user building in Canvas
3. Create a new dbt project.
4. Connect the project repository:
   - Choose GitHub if using GitHub integration.
   - Select the repo that contains `jaffle-shop-synapse`.
   - Set the project branch to `synapse-legacy`, unless you merged that branch into `main`.
5. Add a new Azure Synapse Analytics connection.
6. Use these connection values:
   - Server: Synapse hostname without `,1433`
   - Port: `1433`
   - Database: dedicated SQL pool/database name
   - Authentication: Service Principal
   - Tenant ID: Azure tenant ID
   - Client ID: service principal application/client ID
   - Client secret: service principal secret value
7. Test the connection.
8. Save the project.

## 4. First Build in Studio

Open the project in dbt Studio or the dbt Cloud IDE.

Run:

```bash
dbt deps
```

Load the sample Jaffle data into the `raw` schema:

```bash
dbt seed --full-refresh --vars '{"load_source_data": true}'
```

Build the project:

```bash
dbt build --exclude resource_type:unit_test
```

The attached guide recommends continuing to exclude `resource_type:unit_test` for the sample project because of a previously observed Synapse nested-CTE issue.

At this point, confirm that these marts exist in Synapse and in dbt metadata:

- `locations`
- `orders`
- `customers`
- `products`
- `supplies`
- `order_items`

## 5. Create Deployment Environment and Job

1. Go to Orchestration or Deploy.
2. Create a new environment:
   - Name: `Prod`
   - Type: Production
   - Branch: `synapse-legacy`
   - Schema: `prod`
   - Connection profile: the Azure Synapse profile created above
3. Create a deploy job:
   - Name: `Jaffle Build`
   - Environment: `Prod`
   - Command:

```bash
dbt build --exclude resource_type:unit_test
```

4. Enable docs/catalog metadata generation on the job.
5. Run the job.
6. Confirm the job succeeds and the Catalog/Explore area can see the `locations` and `orders` marts.

Canvas needs usable dbt metadata and a development target. Do not start the Canvas exercise until a production or staging job has completed successfully and metadata is visible.

## 6. Recreate the Canvas Model

If you want to exactly reproduce the attached guide, use the name:

`location_profitability_canvas_v1.sql`

The `synapse-legacy` branch already contains this model. For a clean live demo without overwriting the existing file, use one of these options:

- Create the Canvas output as `location_profitability_canvas_v2.sql`
- Or create a temporary feature branch where the existing `models/canvas/location_profitability_canvas_v1.sql` file is removed before the Canvas exercise

### Canvas Workspace

1. Open Canvas in dbt.
2. Create a workspace named:
   `Location profitability`
3. Canvas will initially create an Output node named something like `Untitled.sql`.

### Add Inputs

1. Add an Input node for:
   `locations`
2. Preview rows and confirm these columns:
   - `location_id`
   - `location_name`
   - `tax_rate`
   - `opened_date`
3. Add an Input node for:
   `orders`
4. Preview rows and confirm these columns:
   - `order_id`
   - `location_id`
   - `order_total`
   - `order_cost`

### Join

1. Add a Join transform.
2. Connect:
   - `locations` to the left input
   - `orders` to the right input
3. Double-click inside the Join node where Canvas says `Combine inputs`.
4. Set Join Type to:
   `Left`
5. Use this advanced expression:

```sql
locations.location_id = orders.location_id
```

Do not use:

```sql
L.location_id = R.location_id
```

The attached guide says the shortcut aliases produced undefined aliases in the tested Canvas/Synapse combination.

In the Join output columns, keep the `locations` side `location_id` and remove the duplicate `orders` side `location_id` if Canvas includes both.

Preview the Join and confirm locations without orders remain present.

### Aggregate

1. Add an Aggregate transform after the Join.
2. Group by:
   - `location_id`
   - `location_name`
   - `tax_rate`
   - `opened_date`
3. Add these metrics:

| Function | Source column | Alias |
| --- | --- | --- |
| `COUNT` or `COUNT_BIG` | `order_id` | `total_orders` |
| `SUM` | `order_total` | `total_revenue` |
| `SUM` | `order_cost` | `total_cost` |
| `AVG` | `order_total` | `average_order_value` |

Canvas may generate `COUNT_BIG` for Synapse. That is acceptable.

Preview the Aggregate and confirm there is one row per location.

### Formula

1. Add a Formula transform after the Aggregate.
2. Use this expression:

```sql
total_revenue - total_cost
```

3. Set Alias to:
   `gross_profit`
4. Preview the Formula and confirm `gross_profit` equals `total_revenue - total_cost`.

### Output

1. Connect the Formula node to the Output node.
2. Rename the model to:
   `location_profitability_canvas_v1.sql`
3. Keep the path:
   `models/canvas`
4. Add this description:

```text
Location-level profitability summary created in dbt Canvas. Includes order count, revenue, cost, average order value, and gross-profit metrics.
```

5. Run the Canvas model.
6. Confirm the run succeeds with:
   - `PASS=1`
   - `WARN=0`
   - `ERROR=0`

## 7. Inspect, Commit, and Merge

1. In Canvas, click SQL.
2. Confirm the generated SQL includes this join:

```sql
from locations
left join orders
on locations.location_id = orders.location_id
```

3. Confirm the aggregate includes:
   - `total_orders`
   - `total_revenue`
   - `total_cost`
   - `average_order_value`
4. Confirm the formula adds:
   - `gross_profit`
5. Commit from Canvas with this message:

```text
Add location_profitability_canvas_v1 generated with dbt Canvas
```

Canvas commits to a `visual-editor/...` branch. It does not merge directly to `synapse-legacy` or `main`.

6. Open the pull request from Studio or GitHub.
7. Target the Synapse branch:
   `synapse-legacy`
8. Review the SQL diff.
9. Merge the pull request.
10. Run the `Jaffle Build` job again with docs/catalog metadata generation enabled.

## 8. Final Validation Checklist

- The new dbt project connects to Azure Synapse successfully.
- `dbt deps` succeeds.
- `dbt seed --full-refresh --vars '{"load_source_data": true}'` succeeds.
- `dbt build --exclude resource_type:unit_test` succeeds.
- The `raw` schema contains the seed tables.
- The `prod` schema contains the mart models.
- Catalog/Explore shows `locations` and `orders`.
- Canvas can create or open the `Location profitability` workspace.
- The Canvas model output has one row per location.
- The generated SQL uses:
  `locations.location_id = orders.location_id`
- The Canvas output file exists under:
  `models/canvas`
- Canvas created a `visual-editor/...` branch and commit.
- The pull request was merged into `synapse-legacy`.
- The production job completed after merge with metadata generation enabled.
- Catalog shows `location_profitability_canvas_v1` and upstream lineage from `locations` and `orders`.

## 9. What to Capture Before the Old Instance Expires

Do this before the old dbt instance disappears:

- Account name and region
- Project name
- Project ID
- Git repo URL
- Production branch
- Environment names and schemas
- Job names, commands, and schedules
- Whether docs/catalog generation is enabled
- Azure Synapse hostname and database name
- Authentication type
- Service principal tenant ID and client ID
- Network allowlist or private-link details
- Any dbt environment variables
- Any custom permissions/user groups related to Canvas

Do not rely on copying old secrets out of dbt Cloud. Create a new service principal secret in Azure and enter it into the new dbt project.

## Source Notes

- Local source PDF: `dbt_canvas_synapse_location_profitability_final_guide.pdf`
- Local cloned repo: `<local-workspace>/jaffle-shop-synapse`
- dbt Canvas docs: `https://docs.getdbt.com/docs/platform/canvas`
- dbt Azure Synapse connection docs: `https://docs.getdbt.com/docs/platform/connect-data-platform/connect-azure-synapse-analytics`
- dbt deployment environments docs: `https://docs.getdbt.com/docs/deploy/deploy-environments`
- dbt GitHub connection docs: `https://docs.getdbt.com/docs/platform/git/connect-github`
