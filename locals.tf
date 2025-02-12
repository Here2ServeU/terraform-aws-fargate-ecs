locals {
  container_definitions = jsonencode([
    for definition in var.container_definitions : merge({
      for key, value in definition :
      key => try(
        # handle value that is a list
        try(toset(value), [
          for k, v in value : {
            name                                     = k
            key == "secrets" ? "valueFrom" : "value" = v
        }]),
      value)
      },
      lookup(definition, "portMappings", null) == null ? {
        portMappings = [
          {
            containerPort = tonumber(definition.container_port)
            hostPort      = tonumber(definition.container_port)
          }
        ]
      } : {},
      try(lookup(definition, "log_configuration", null) == null ? {
        logDriver = "awslogs"

        options = {
          awslogs-region        = var.region
          awslogs-stream-prefix = definition.name
          awslogs-group         = aws_cloudwatch_log_group.log.name
        }
      } : {}, {})

    )
  ])

  first_container     = var.container_definitions[0]
  main_container_name = local.first_container.name
  main_container_port = local.first_container.container_port
}
