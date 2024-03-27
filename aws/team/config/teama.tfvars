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


