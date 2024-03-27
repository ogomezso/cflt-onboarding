locals {
  env_service_accounts     = distinct(var.team_resources.*.service_account)
  cluster_service_accounts = distinct(var.team_resources.*.kafka_cluster.service_account)
  service_accounts         = concat(local.env_service_accounts, local.cluster_service_accounts)
}

module "create_service_accounts" {
  for_each = toset(local.service_accounts)
  source   = "github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5"
  providers = {
    confluent = confluent.confluent_cloud
  }
  service_account = {
    name        = each.value
    description = "Service Account ${each.value}"
  }
}

module "create_environments" {
  for_each = {
    for index, env in var.team_resources :
    env.name => env
  }
  source = "github.com/ogomezso/terraform-confluent-environment?ref=v1.0.2"
  providers = {
    confluent = confluent.confluent_cloud
  }
  display_name   = each.value.name
  cloud_provider = each.value.cloud_provider
  region         = each.value.region
  sr_package     = each.value.sr_package
  env_manager_sa = each.value.service_account

  depends_on = [
    module.create_service_accounts
  ]
}

module "create_environments_adminroles" {
  for_each = {
    for index, env in var.team_resources :
    env.name => env
  }
  source = "github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5"
  providers = {
    confluent = confluent.confluent_cloud
  }
  environment_role_bindings = {
    service_account = each.value.service_account
    environment     = each.value.name
  }

  depends_on = [
    module.create_environments,
    module.create_service_accounts
  ]
}

module "create_kafka_clusters" {
  for_each = {
    for index, env in var.team_resources :
    env.name => env
  }
  source = "github.com/mcolomerc/terraform-confluent-kafka-cluster?ref=v1.0.1"
  providers = {
    confluent.confluent_cloud = confluent
  }
  environment = each.value.name
  cluster = {
    display_name = each.value.kafka_cluster.name
    availability = each.value.kafka_cluster.availability
    cloud        = each.value.kafka_cluster.cloud
    region       = each.value.kafka_cluster.region
    type         = each.value.kafka_cluster.type
  }
  depends_on = [
    module.create_environments,
    module.create_service_accounts
  ]
}

module "kafka_cluster_admin_service_account_role_binding" {
  for_each = {
    for index, env in var.team_resources :
    env.name => env
  }
  source = "github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5"
  providers = {
    confluent = confluent.confluent_cloud
  }
  cluster_role_bindings = {
    service_account = each.value.kafka_cluster.service_account
    cluster         = each.value.kafka_cluster.name
    environment     = each.value.name
    sa_role_bindings = [{
      role = "CloudClusterAdmin"
      name = "cluster"
    }]
  }
  depends_on = [
    module.create_kafka_clusters
  ]
}

module "create_idp_role_binding" {
  for_each = {
    for index, env in var.team_resources :
    env.name => env
    if env.idps != null
  }
  source = "github.com/mcolomerc/terraform-confluent-iam?ref=v1.0.5"
  providers = {
    confluent = confluent.confluent_cloud
  }
  identity_pool_role_bindings = {
    environment       = each.value.name
    cluster           = each.value.kafka_cluster.name
    identity_provider = each.value.idps.identity_provider
    identity_pools    = each.value.idps.identity_pools
  }
  depends_on = [
    module.create_kafka_clusters
  ]
}

module "create_ksql_cluster" {
  for_each = {
    for index, env in var.team_resources :
    env.name => env
    if env.ksql_cluster != null
  }
  source = "github.com/ogomezso/terraform-confluent-ksql-cluster?ref=v1.0.0"
  providers = {
    confluent = confluent.confluent_cloud
  }
  environment     = each.value.name
  kafka_cluster   = each.value.kafka_cluster.name
  ksql_cluster    = each.value.ksql_cluster.name
  csu             = each.value.ksql_cluster.csu
  service_account = each.value.kafka_cluster.service_account
  depends_on = [
    module.create_kafka_clusters,
    module.kafka_cluster_admin_service_account_role_binding
  ]
}
