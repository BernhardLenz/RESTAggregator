variable "github_token" {
  description = "The GitHub Token to be used for the CodePipeline. You can pass this variable through the command line using e.g. 'terraform plan -var=\"github_token=66160b0f39ad666ee5af01ede5660def90064ccc\"'\nSee https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line"
  type        = string
}

variable "github_owner" {
  description = "The owner of the github repository for above token (e.g. BernhardLenz in https://github.com/BernhardLenz/RESTAggregator). You can pass this variable through the command line using e.g. 'terraform plan -var=\"github_owner=BernhardLenz\"'"
  type        = string
}

variable "github_repo" {
  description = "The name of the github repository for above token (e.g. RESTAggregator in https://github.com/BernhardLenz/RESTAggregator). The default is RESTAggregator."
  type        = string
  default     = "RESTAggregator"
}

variable "profile" {
  description = "The .aws profile to use to connect to aws (\"default\" is the default). "
  type        = string
  default     = "default"
}

variable "region" {
  description = "The region to deploy to (us-east-1 is the default). "
  type        = string
  default     = "us-east-1"
}

variable "s3bucket4deploy" {
  description = "A unique s3 bucket to store the deployment artificats (e.g. com.bernhardlenz.restagg-codepipeline). You can pass this variable through the command line using e.g. 'terraform plan -var=\"s3bucket4deploy=com.bernhardlenz.restagg-codepipeline\"'"
  type        = string
}

variable "s3bucket4results" {
  description = "A unique s3 bucket to store the output of the RESTAggregator (e.g. com.bernhardlenz.restagg-results). You can pass this variable through the command line using e.g. 'terraform plan -var=\"s3bucket4results=com.bernhardlenz.restagg-results\"'"
  type        = string
}

# The shedule on which to run the fargate task. Follows the CloudWatch Event Schedule Expression format: https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
variable "schedule_expression" {
  description = "Cron expression specifying how often the ecs task should run. The cron format is (min) (hour) (day of month) (month) (day of week) (year) (e.g. * 17,18,19 30 DEC ? 2020 for every minute on 12/31/2020 between 5pm and 7pm GMT). You can pass this variable through the command line using e.g. 'terraform plan -var=\"schedule_expression=cron(* 17,18,19 30 DEC ? 2020)\"'"
  type        = string
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_caller_identity" "current" {}
