module "devops" {
  source = "./.."

  name             = "hello_world"
  account_id       = "123456789012"
  region           = "us-east-1"
  githook_provider = "Bitbucket"

  projects = [
    {
      name         = "api"
      git_repo     = "example-api"
      is_container = true
      dockerfile   = "./Dockerfile"
      vpc_id       = ""

      vpc_subnets = []

      pipelines = [
        { name = "dev", branch_name = "dev" },
        { name = "release", branch_name = "release/*" },
      ]

      stages = {
        test = {
          unit = true
          int  = false
        }

        deploy = {
          qa   = true
          prod = true
        }
      }

      jobs = [
        {
          branch_name      = "dev"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "local"

          action      = "build"
          action_item = "container"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
        {
          branch_name      = "release"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "local"

          action      = "build"
          action_item = "container"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
        {
          branch_name      = "release"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "test"

          action      = "deploy"
          action_item = "container_app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
        {
          branch_name      = "release"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "qa"

          action      = "deploy"
          action_item = "container_app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
        {
          branch_name      = "release"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "prod"

          action      = "deploy"
          action_item = "container_app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
      ]
    },
  ]
}
