terraform {
  required_providers {
    skopeo2 = {
      source  = "bsquare-corp/skopeo2"
      version = "~> 1.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "skopeo2" {
  source {
    login_username = "my-source-registry-username"
    login_password = "my-source-registry-password"
  }
  destination {
    login_username = "my-destination-registry-username"
    login_password = "my-destination-registry-password"
  }
}

module "devops_cloud" {
  source = "./.."

  name       = "hello_world"
  account_id = "123456789012"
  region     = "us-east-1"

  repositories = [
    {
      name         = "cloud"
      git_provider = "Bitbucket"
      git_repo     = "example-cloud"
      is_container = false
      dockerfile   = ""
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
          action_item = "cloud"

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
          action_item = "cloud"

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
          action_item = "cloud"

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
          action_item = "cloud"

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
          action_item = "cloud"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
      ]
    }
  ]
}

module "devops_container_app" {
  source = "./.."

  name       = "hello_world"
  account_id = "123456789012"
  region     = "us-east-1"

  repositories = [
    {
      name         = "container-api"
      git_provider = "Bitbucket"
      git_repo     = "example-container-api"
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
          action_item = "container-app"

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
          action_item = "container-app"

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
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
        },
      ]
    }
  ]
}
