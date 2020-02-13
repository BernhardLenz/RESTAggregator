# Bernie Lenz's rough example of a scheduled REST API Aggregator

##### Components created
- 1 VPC
- 2 Availability Zones
- 1 Public Subnet and 1 Private Subnet per AZ
- 2 NATs, 1 in earch Public Subnet
- 1 Internet Gateway in VPC
- 1 S3 Endpoint inside the VPC so the traffic to S3 doesn't traverse the internet
- Sample python script which calls 2 REST APIS and combines both into one output
- ECS/Fargate
- Scheduled ECS tasks using Cloudwatch Events
- CodePipeline
- CodeBuild
- S3 Bucket for build artifacts
- S3 Bucket for output of REST Aggegator python script
- Environment Variable declared in ECS to be used by the node container to be displayed in the web page

##### Run Instructions
- Install AWS cli and make sure you have a profile defined in the configuration files in the .aws directory. Consider running this project in a separate account. 
- Install terraform. v0.12.19 is required
- Fork https://github.com/BernhardLenz/RESTAggregator to your own github space and create/retrieve an access code (See https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)
- clone your github directory to your local drive
- cd into the terraform directory and run e.g. 
``` 
terraform init
terraform apply \
    -var="github_token=5ab3d39c35233246391a96d320d1d3606064de9e" \
    -var="profile=default" \
    -var="github_owner=BernhardLenz" \
    -var="s3bucket4deploy=com.bernhardlenz.restagg-codepipeline" \
    -var="s3bucket4results=com.bernhardlenz.restagg-results" \
    -var="schedule_expression=cron(* * * * ? 2020)"
``` 
- It might take a few minutes after the terraform scripts finish for the code to be deployed and become ready. If the application does not come up you may have to kick off the CodePipeline manually to perform an initial deployment. 

##### Notes, thoughts and ToDos
- The python script does not upload the results to s3 yet. As a ToDo the script needs to be expanded to upload its output to s3 using the aws boto libraries via the s3 endpoint
- Currently the script can only be run every minute as the Cloudwatch Event Scheduler granularity is minutes. For sub-minute scheduling the script needs to be modified to contain a loop with wait statements passed in as an environment variable and the scheduling of the task has to be changed to one-time cron schedules rather than repeating cron schedules. 