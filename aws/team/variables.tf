variable "team_resources" {
  type = list(object({
    name            = string
    service_account = string
    cloud_provider  = string
    region          = string
    sr_package      = string
    kafka_cluster = object({
      name            = string
      service_account = string
      availability    = string
      cloud           = string
      region          = string
      type            = string
    })
    idps = optional(object({
      identity_provider = string
      identity_pools = list(object({
        identity_pool = object({
          display_name   = string
          description    = string
          identity_claim = string
          filter         = string
        })
        roles = list(object(
          {
            role            = string
            resource        = string
            resource_prefix = string
        }))
      }))
    }))
    ksql_cluster = optional(object({
      name = string
      csu  = string
    }))
  }))
  default = null
}
