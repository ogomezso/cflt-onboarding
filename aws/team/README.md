# Process Automation for Team Onboarding 

This is terraform module that serve as example for automated team onboarding process to Confluent Cloud

The example is based on terraform modules that abstract the use of the [Confluent Cloud Terraform Provider](https://registry.terraform.io/providers/confluentinc/confluentcloud/latest/docs) desacoplando asó el conocimiento 
necesario para poder crear/mantener los recursos necesarios para el equipo.

Is delivered as a terraform script (main.tf) that is configurable by a terraform variable file (tf.vars).

The solution propose that each team will have their own variable file that describes their need. As demo these files are located on the `config` folder on the same code repository, but for there you will need to figure out what is the best method to distribute this configuration and script through one or more code repositories with different owners and approval processes depending on the CI/CD runner of your choice.

As pre-requisite you will need to create a administration Service Account that will be used by terraform to execute the scripts. 

This automated process has the capability to create one or more environment that will have:

## Admin Service Account

As first step we need to create the Service Accounts that will have administration permissions for out environment and clusters: 

- One administrator for each environment to be created
- One administrator for each Kafka Cluster to be created inside each environment.

### Dependencies

Module:

<https://github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5>

## Environment

On this block we will be creating a Confluent Cloud environment that will contain our Kafka Clusters. This phase creates:

- Confluent Environment
- `EnvironmentAdmin` role assigment for the proper Service Account.
- `Schema Registry` package creation
- Schema Registry specific API Key creation

### Dependencies:

<https://github.com/ogomezso/terraform-confluent-environment?ref=v1.0.2>
<https://github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5>

## Kafka Cluster

This block will create a Kafka Cluster for each created environment, we can see this cluster as the one in which each team expose their `data products` but also the one where the use cases or applications without enough entity to justify a dedicated cluster expose their internal data. 

Como parte del proceso de creación del cluster se realizan las siguientes tareas: 
In addition to the Kafka Cluster creation this block also assign the `ClusterAdmin` role to the service account that was created by the previous block 

### Dependencies

<https://github.com/mcolomerc/terraform-confluent-kafka-cluster?ref=v1.0.1>
<https://github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5>

## Identities (TO BE SEPARATE ON A DIFFERENT SCRIPT)

This block create `identity pools` for the `devops` and `developer` role over a given `identity provider` and assign the proper roles for the team resources.

### Dependencies

<https://github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5>

## KSQL DEFAULT

Optionally we can create a KSQL Cluster associated to the Kafka Cluster one.

The Kafka Cluster Admin account will act as KSQL Admin too.

### Dependencies

<https://github.com/ogomezso/terraform-confluent-ksql-cluster?ref=v1.0.0>

## Usage

 With this `tfvars`  file located on the `config` folder:

```terraform
team_resources = [
  {
    name            = "ogomez_teama_dev"
    service_account = "ogomez_teama_dev_env_sa"
    cloud_provider  = "AWS"
    region          = "eu-central-1"
    sr_package      = "ESSENTIALS"
    kafka_cluster = {
    name            = "ogomez_teama_dev_default"
    service_account = "ogomez_teama_dev_default_cluster_sa"
    availability    = "SINGLE_ZONE"
    cloud           = "AWS"
    region          = "eu-central-1"
    type            = "STANDARD"
  }
  idps = {
    identity_provider = "op-q0G"
    identity_pools = [
    {
      identity_pool = {
      display_name   = "ogomez_teama_dev_devops"
      description    = "Dev ADM Pool"
      identity_claim = "claims.sub"
      filter         = "claims.aud=='1326f8fe-6d30-456b-a34c-93f13cac0da1' && claims.scp=='mapfre.devops'"
    }
    roles = [
      {
        role            = "ResourceOwner"
        resource        = "topic"
        resource_prefix = "ogomez.teama.biz*"
      },
      {
        role            = "ResourceOwner"
        resource        = "group"
        resource_prefix = "ogomez.teama.tech*"
      }]
  },
    {
      identity_pool = {
      display_name   = "ogomez_teama_dev_developer"
      description    = "Dev ADM Pool"
      identity_claim = "claims.sub"
      filter         = "claims.aud=='1326f8fe-6d30-456b-a34c-93f13cac0da1' && claims.scp in ['ogomez.producer', 'ogomez.consumer', 'ogomez.developer']"
    }
    roles = [
      {
        role            = "DeveloperRead"
        resource        = "topic"
        resource_prefix = "ogomez.teama.biz*"
      },
      {
        role            = "DeveloperWrite"
        resource        = "topic"
        resource_prefix = "ogomez.teama.biz*"
      },
      {
        role            = "DeveloperRead"
        resource        = "topic"
        resource_prefix = "ogomez.teama.tech*"
      },
      {
        role            = "DeveloperWrite"
        resource        = "topic"
        resource_prefix = "ogomez.teama.tech*"
      },
      {
        role            = "DeveloperRead"
        resource        = "topic"
        resource_prefix = "ogomez.teamb.biz*"
      }
    ]
  }
  ]
}
},
  {
    name            = "ogomez_teama_pro"
    service_account = "ogomez_teama_pro_env_sa"
    cloud_provider  = "AWS"
    region          = "eu-central-1"
    sr_package      = "ESSENTIALS"
    kafka_cluster = {
    name            = "ogomez_teama_pro_default"
    service_account = "ogomez_teama_pro_default_cluster_sa"
    availability    = "SINGLE_ZONE"
    cloud           = "AWS"
    region          = "eu-central-1"
    type            = "STANDARD"
  }
  ksql_cluster = {
    name = "ogomez_teama_ksql_pro_default"
    csu  = "1"
  }
}
]
```
you need to execute:

`terraform init --upgrade`

for terraform module and providers initialization

`terraform plan -var-file="config/teama.tfvars" -out config/teama_tf.plan`

with the terraform execution file as output.

`terraform apply config/team.plan`

finally we apply the terraform execution plan.

With this we will be creating:

- Environment: ogomez_teama_dev
    - Environment Admin Service Account: ogomez_teama_dev_env_sa
    - Schema Registry: Essentials package on  AWS eu-central-1 zone and its the admin API KEY
    - Kafka Cluster: ogomez_teama_dev_default, Standard, Single zone, Region eu-central-1 in AWS
        - Admin Service Account: ogomez_dev_default_cluster_sa
        - NO KSql cluster
    - Identity Providers:
      - ogomez_teama_dev_devops
      - ogomez_teama_dev_developer
- Environment: ogomez_team_pro
    - Admin Service Account: ogomez_teama_pro_env_sa
    - Schema Registry: Essentials on eu-central-1 AWS zone and its admin API KEY
    - Kafka Cluster: ogomex_teama_pro_default, Standard, Single zone, Region eu-central-1 on AWS
        - Admin Service Account: ogomez_teama_pro_default_cluster_sa
        - ogomez_teama_ksql_pro_default con 1 CSU


## Terraform Docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_confluent"></a> [confluent](#requirement\_confluent) | >=1.51.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_create_environments"></a> [create\_environments](#module\_create\_environments) | github.com/ogomezso/terraform-confluent-environment | v1.0.2 |
| <a name="module_create_environments_adminroles"></a> [create\_environments\_adminroles](#module\_create\_environments\_adminroles) | github.com/mcolomerc/terraform-confluent-iam | v1.0.5 |
| <a name="module_create_idp_role_binding"></a> [create\_idp\_role\_binding](#module\_create\_idp\_role\_binding) | github.com/mcolomerc/terraform-confluent-iam | v1.0.5 |
| <a name="module_create_kafka_clusters"></a> [create\_kafka\_clusters](#module\_create\_kafka\_clusters) | github.com/mcolomerc/terraform-confluent-kafka-cluster | v1.0.1 |
| <a name="module_create_ksql_cluster"></a> [create\_ksql\_cluster](#module\_create\_ksql\_cluster) | github.com/ogomezso/terraform-confluent-ksql-cluster | v1.0.0 |
| <a name="module_create_service_accounts"></a> [create\_service\_accounts](#module\_create\_service\_accounts) | github.com/mcolomerc/terraform-confluent-iam | v1.0.5 |
| <a name="module_kafka_cluster_admin_service_account_role_binding"></a> [kafka\_cluster\_admin\_service\_account\_role\_binding](#module\_kafka\_cluster\_admin\_service\_account\_role\_binding) | github.com/mcolomerc/terraform-confluent-iam | v1.0.5 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_team_resources"></a> [team\_resources](#input\_team\_resources) | n/a | <pre>list(object({<br>    name            = string<br>    service_account = string<br>    cloud_provider  = string<br>    region          = string<br>    sr_package      = string<br>    kafka_cluster = object({<br>      name            = string<br>      service_account = string<br>      availability    = string<br>      cloud           = string<br>      region          = string<br>      type            = string<br>    })<br>    idps = optional(object({<br>      identity_provider = string<br>      identity_pools = list(object({<br>        identity_pool = object({<br>          display_name   = string<br>          description    = string<br>          identity_claim = string<br>          filter         = string<br>        })<br>        roles = list(object(<br>          {<br>            role            = string<br>            resource        = string<br>            resource_prefix = string<br>        }))<br>      }))<br>    }))<br>    ksql_cluster = optional(object({<br>      name = string<br>      csu  = string<br>    }))<br>  }))</pre> | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->