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

module "complete" {
  source = "./.."

  name       = "hello_world"
  account_id = "123456789012"
  region     = "us-east-1"

  repositories = [
    {
      name         = "api"
      git_provider = "Bitbucket"
      git_repo     = "example-api"
      is_container = true
      dockerfile   = "Dockerfile"

      pipelines = [
        { type = "complete", branch_name = "develop" },
        { type = "complete", branch_name = "main" },
      ]

      stages = {
        test = {
          unit = true
          int  = true
        }

        deploy = {
          test = true
          qa   = true
          prod = true
        }
      }

      jobs = [
        {
          branch_name = "develop"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "local"
          target_runtime   = ""
          test_commands    = []

          action      = "build"
          action_item = "container"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "develop"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          target_runtime   = ""
          environment_name = "unit-test"

          test_commands = [
            "npm i",
            "npm run build",
            "npm run unit-test",
          ]

          action      = "run"
          action_item = "test"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "local"
          target_runtime   = ""
          test_commands    = []

          action      = "build"
          action_item = "container"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "unit-test"
          target_runtime   = ""

          test_commands = [
            "npm i",
            "npm run build",
            "npm run unit-test",
          ]

          action      = "run"
          action_item = "test"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "test"
          target_runtime   = ""
          test_commands    = []

          action      = "deploy"
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "int-test"
          target_runtime   = ""

          test_commands = [
            "npm i",
            "npm run build",
            "npm run int-test",
          ]

          action      = "run"
          action_item = "test"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "qa"
          target_runtime   = ""
          test_commands    = []

          action      = "deploy"
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "prod"
          target_runtime   = ""
          test_commands    = []

          action      = "deploy"
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
      ]
    }
  ]
}

module "build" {
  source = "./.."

  name       = "hello_world"
  account_id = "123456789012"
  region     = "us-east-1"

  repositories = [
    {
      name         = "api"
      git_provider = "Bitbucket"
      git_repo     = "example-api"
      is_container = true
      dockerfile   = "Dockerfile"

      pipelines = [
        { type = "build", branch_name = "main" },
      ]

      stages = {
        test = {
          unit = true
          int  = false
        }

        deploy = {
          test = false
          qa   = false
          prod = false
        }
      }

      jobs = [
        {
          branch_name = "develop"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "local"
          target_runtime   = ""
          test_commands    = []

          action      = "build"
          action_item = "container"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "develop"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          target_runtime   = ""
          environment_name = "unit-test"

          test_commands = [
            "npm i",
            "npm run build",
            "npm run unit-test",
          ]

          action      = "run"
          action_item = "test"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "local"
          target_runtime   = ""
          test_commands    = []

          action      = "build"
          action_item = "container"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "unit-test"
          target_runtime   = ""

          test_commands = [
            "npm i",
            "npm run build",
            "npm run unit-test",
          ]

          action      = "run"
          action_item = "test"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
      ]
    }
  ]
}

module "release" {
  source = "./.."

  name       = "hello_world"
  account_id = "123456789012"
  region     = "us-east-1"

  repositories = [
    {
      name         = "api"
      git_provider = "Bitbucket"
      git_repo     = "example-api"
      is_container = true
      dockerfile   = "Dockerfile"

      pipelines = [
        { type = "release", branch_name = "main" },
      ]

      stages = {
        test = {
          unit = false
          int  = true
        }

        deploy = {
          test = true
          qa   = true
          prod = true
        }
      }

      jobs = [
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "test"
          target_runtime   = ""
          test_commands    = []

          action      = "deploy"
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "int-test"
          target_runtime   = ""

          test_commands = [
            "npm i",
            "npm run build",
            "npm run int-test",
          ]

          action      = "run"
          action_item = "test"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "qa"
          target_runtime   = ""
          test_commands    = []

          action      = "deploy"
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
        {
          branch_name = "main"

          vpc_id                 = ""
          vpc_subnets            = []
          vpc_security_group_ids = []

          image            = "aws/codebuild/standard:7.0"
          timeout          = 5
          working_dir      = "./"
          ssm_param_paths  = ""
          environment_name = "prod"
          target_runtime   = ""
          test_commands    = []

          action      = "deploy"
          action_item = "container-app"

          task_family                  = ""
          task_role                    = ""
          container_port               = ""
          container_cpu                = ""
          container_memory_reservation = ""
          cluster_name                 = ""
          service_name                 = ""
          log_group_name               = ""
          log_stream_prefix            = ""
        },
      ]
    }
  ]
}
