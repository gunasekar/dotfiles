#!/usr/bin/env bash

export AWS_SDK_LOAD_CONFIG=1

alias aws-nopager="export AWS_PAGER=\"\""
alias aws-pager-less="export AWS_PAGER=\"less\""

# Cross-platform date formatting helper
# Converts macOS-style date arguments (e.g., -120M, -0S) to ISO format
# Usage: portable-date "-120M" -> returns ISO timestamp 120 minutes ago
function portable-date() {
    local offset=$1

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: use -v flag
        date -v "$offset" -u +%FT%TZ
    else
        # Linux: parse and convert the macOS format to GNU date format
        # Extract number and unit (e.g., -120M -> 120 minutes ago)
        local num=$(echo "$offset" | sed 's/[^0-9-]//g')
        local unit=$(echo "$offset" | sed 's/[0-9-]//g')

        case $unit in
            M) date -u -d "$num minutes ago" +%FT%TZ ;;
            S) date -u -d "$num seconds ago" +%FT%TZ ;;
            H) date -u -d "$num hours ago" +%FT%TZ ;;
            d) date -u -d "$num days ago" +%FT%TZ ;;
            *) echo "Unknown time unit: $unit" >&2; return 1 ;;
        esac
    fi
}

function show-aws-creds {
    cat ~/.aws/credentials
}

function get-aws-identity {
    aws sts get-caller-identity
}

### local aws
function create-dynamo-table {
    awslocal dynamodb create-table --table-name $1  --attribute-definitions AttributeName=id,AttributeType=S --key-schema AttributeName=id,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
}

function create-sqs-queue {
    awslocal sqs create-queue --queue-name $1
}

function launch-dynamodb-admin {
    export DYNAMO_ENDPOINT=http://localhost:4569
    export PORT=8050
    dynamodb-admin
}

##### ECS
function ecs-clusters {
    aws ecs list-clusters --output json | jq -r ".clusterArns[] | select(contains(\"$1\"))"
}

function ecs-services {
    [[ $# != 1 ]] && { echo "$0 <cluster-name> \nExamples:\n$0 some-ecs-cluster"; return; }
    aws ecs list-services --cluster $1 --output json
}

function internal-ecs-get-service {
    serviceFilter=`echo "$2[a-zA-Z0-9\-]*"`
    echo `aws ecs list-services --cluster $1 | grep -o $serviceFilter`
}

function ecs-service {
    [[ $# != 2 ]] && { echo "$0 <cluster-name> <service-name> \nExamples:\n$0 some-ecs-cluster some-service"; return; }
    internal-ecs-describe-service "serviceOnly" "$@"
}

function ecs-service-events {
    [[ $# != 3 ]] && { echo "$0 <cluster-name> <service-name> <number_of_events> \nExamples:\n$0 some-ecs-cluster some-service 5"; return; }
    internal-ecs-describe-service "serviceEventsOnly" "$@"
}

function ecs-service-task-definition {
    [[ $# != 2 ]] && { echo "$0 <cluster-name> <service-name> \nExamples:\n$0 some-ecs-cluster some-service"; return; }
    internal-ecs-describe-service "taskDefinition" "$@"
}

function internal-ecs-describe-service {
    action=$1
    clusterName=$2
    serviceSimpleName=$3

    serviceName=`internal-ecs-get-service $clusterName $serviceSimpleName`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return; }
    serviceDesc=`aws ecs describe-services --cluster $clusterName --service $serviceName`

    case "$action" in
        serviceOnly)
            echo $serviceDesc | jq ".services[] | {serviceName, status, desiredCount, runningCount, pendingCount, launchType, taskDefinition, clusterArn, loadBalancers, roleArn}"
            ;;

        taskDefinition)
            tdFilter=`echo "$serviceSimpleName:[0-9]*"`
            taskDefinition=`echo $serviceDesc | jq ".services[].taskDefinition" | grep -o $tdFilter`
            taskDefinitionDesc=`aws ecs describe-task-definition --task-definition $taskDefinition`
            echo $taskDefinitionDesc | jq ".taskDefinition.taskDefinitionArn"

            jqParam=`echo ".taskDefinition.containerDefinitions[] | select(.name == \"$serviceSimpleName\") | {name, image, cpu, memory, portMappings, ulimits, logConfiguration}"`
            echo $taskDefinitionDesc | jq $jqParam
            ;;

        serviceEventsOnly)
            jqParam=".services[].events[0:$4]"
            echo $serviceDesc | jq $jqParam
            ;;
    esac
}

function ecs-service-complete {
    [[ $# != 2 ]] && { echo "$0 <cluster-name> <service-name> \nExamples:\n$0 some-ecs-cluster some-service"; return; }

    serviceName=`internal-ecs-get-service "$@"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return; }
    serviceDesc=`aws ecs describe-services --cluster $1 --service $serviceName`
    echo ">>> Service"
    echo $serviceDesc | jq

    tdFilter=`echo "$2:[0-9]*"`
    taskDefinition=`echo $serviceDesc | jq ".services[].taskDefinition" | grep -o $tdFilter`
    taskDefinitionDesc=`aws ecs describe-task-definition --task-definition $taskDefinition`
    echo ">>> Task Definition"
    echo $taskDefinitionDesc | jq
}

function ecs-force-deploy {
    [[ $# != 2 ]] && { echo "$0 <cluster-name> <service-name> \nExamples:\n$0 some-ecs-cluster some-service"; return; }
    serviceName=`internal-ecs-get-service "$@"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return; }
    aws ecs update-service --cluster $1 --service $serviceName --force-new-deployment | jq ".service | {serviceName, status, desiredCount, runningCount, pendingCount, launchType, taskDefinition, clusterArn, loadBalancers, roleArn}"
}

function ecs-set-desired-count {
    [[ $# != 3 ]] && { echo "$0 <cluster-name> <service-name> <num_of_instances>\nExamples:\n$0 some-ecs-cluster some-service 3"; return; }
    serviceName=`internal-ecs-get-service "$@"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return; }
    aws ecs update-service --cluster $1 --service $serviceName --desired-count $3 | jq ".service | {serviceName, status, desiredCount, runningCount, pendingCount, launchType, taskDefinition, clusterArn, loadBalancers, roleArn}"
}

##### SSM
function ssm-list-params() {
    [[ $# != 1 ]] && { echo "$0 <path>"; return; }
    parameter_path=$1
    aws ssm get-parameters-by-path --path $parameter_path --with-decryption --recursive | \
        jq '.Parameters |= sort_by(.Name) | {Parameters: [.Parameters[] | {Name, Type, Value}]}'
}

function ssm-to-exports() {
    [[ $# != 1 ]] && { echo "Usage: ssm-to-exports <path>"; return 1; }
    parameter_path=$1
    aws ssm get-parameters-by-path --path "$parameter_path" --with-decryption --recursive | \
        jq -r '.Parameters | sort_by(.Name) | .[] | "export \(.Name | split("/")[-1])='\''\(.Value)'\''"'
}

function ssm-add-update-params() {
    # Check if at least input file is provided
    [[ $# -lt 1 ]] && {
        echo "Usage: $0 <input_json_file> [options]"
        echo "Options:"
        echo "  -n, --name <param_name>  Update only the specified parameter"
        echo "  -k, --key-id <key_id>    Use specified KMS key (default: alias/aws/ssm)"
        return 1
    }

    local inputFile=""
    local targetName=""
    local keyId="alias/aws/ssm"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                targetName="$2"
                shift 2
                ;;
            -k|--key-id)
                keyId="$2"
                shift 2
                ;;
            *)
                inputFile="$1"
                shift
                ;;
        esac
    done

    [[ -z "$inputFile" ]] && { echo "Error: Input file is required"; return 1; }

    i=0
    loopFlag=true
    while $loopFlag
    do
        # Updated jq path to handle new JSON structure
        node=`cat $inputFile | jq ".Parameters[$i]"`
        name=`cat $inputFile | jq ".Parameters[$i].Name" | sed -e 's/^"//' -e 's/"$//' `

        node=`echo $node`
        if [ "$node" != "null" ]
        then
            # Skip if targetName is specified and doesn't match
            if [[ -n "$targetName" && "$targetName" != "$name" ]]; then
                i=`expr $i + 1`
                continue
            fi

            newValue=`cat $inputFile | jq ".Parameters[$i].Value" | sed -e 's/^"//' -e 's/"$//'`

            # Only pick the required fields
            node=$(echo "$node" | jq '{Name, Type, Value}')

            # Add KeyId to SecureString parameters
            if [ "$(echo "$node" | jq -r '.Type')" = "SecureString" ]; then
                node=$(echo "$node" | jq --arg kid "$keyId" '. + {"KeyId": $kid}')
            fi

            local oldVersion=0
            local oldValue=""
            if result=$(aws ssm get-parameter --name "$name" --with-decryption 2>/dev/null); then
                oldVersion=$(echo "$result" | jq -r '.Parameter.Version')
                oldValue=$(echo "$result" | jq -r '.Parameter.Value')

                if [ "$oldValue" = "$newValue" ]; then
                    echo "ssm parameter :: $name"
                    echo -e "\tvalue unchanged (version: $oldVersion)"
                else
                    newVersion=`aws ssm put-parameter --cli-input-json "$node" --overwrite --output json | jq ".Version"`
                    echo "ssm put-parameter :: $name"
                    echo -e "\tvalue: $oldValue -> $newValue"
                    echo -e "\tversion: $oldVersion -> $newVersion"
                fi
            else
                newVersion=`aws ssm put-parameter --cli-input-json "$node" --output json | jq ".Version"`
                echo "ssm put-parameter :: $name"
                echo -e "\tvalue: (new parameter) -> $newValue"
                echo -e "\tversion: 0 -> $newVersion"
            fi

            # If we found and processed the target parameter, we can exit
            [[ -n "$targetName" ]] && break

            i=`expr $i + 1`
        else
            loopFlag=false
        fi
    done
}

function ssm-delete-params() {
    [[ $# != 1 ]] && { echo "$0 <path>"; return; }
    parameter_path=$1
    aws ssm get-parameters-by-path --path $parameter_path --recursive | jq '.Parameters[].Name' | xargs -L1 -I'{}' aws ssm delete-parameter --name {}
}


##### S3
function s3() {
    aws s3api list-buckets | jq -r ".Buckets[].Name | select(contains(\"$1\"))"
}

function s3-ls() {
    [[ $# != 2 ]] && { echo "$0 <bucket> <prefix>"; return; }
    aws s3api list-objects --bucket $1 --prefix $2 | jq -r '.Contents[]' | jq -r -j '.LastModified, "\t\t",.Key, "\n"'
}

function s3-ls-contains() {
    [[ $# != 3 ]] && { echo "$0 <bucket> <prefix> <key_contains>"; return; }
    aws s3api list-objects --bucket $1 --prefix $2 --query "Contents[?contains(Key, '$3')]" | jq -r ".[].Key"
}

function s3-cat() {
    [[ $# != 2 ]] && { echo "$0 <bucket> <key>"; return; }
    aws s3 cp s3://$1/$2 -
}

function s3-dl() {
    if [[ $# -lt 2 ]] || [[ $# -gt 3 ]]; then
        echo "Usage: $0 <bucket> <key> [target_folder]"
        echo "Examples:"
        echo "  $0 my-bucket path/to/file.txt             # Downloads as file.txt"
        echo "  $0 my-bucket path/to/file.txt downloads/  # Downloads to downloads/file.txt"
        echo "  $0 my-bucket path/to/files/               # Downloads all files recursively"
        echo "  $0 my-bucket path/to/files/ downloads/    # Downloads all files to downloads/"
        return 2
    fi

    local bucket=$1
    local key=$2
    local target=$3

    # Parameter validation
    [[ -z "$bucket" ]] && { echo "Error: Bucket name cannot be empty" >&2; return 1; }
    [[ -z "$key" ]] && { echo "Error: Key cannot be empty" >&2; return 1; }

     # If target directory specified, check if it exists or can be created
    if [[ -n "$target" ]] && [[ "$target" == */ ]]; then
        if [[ ! -d "$target" ]] && ! mkdir -p "$target"; then
            echo "Error: Cannot create target directory: $target" >&2
            return 1
        fi
    fi

    # Check if key ends with / - indicates directory/prefix
    if [[ $key == */ ]]; then
        # Recursive download
        if [ -n "$target" ]; then
            aws s3 cp "s3://$bucket/$key" "$target" --recursive
        else
            aws s3 cp "s3://$bucket/$key" "./" --recursive
        fi
    else
        # Single file download
        if [ -n "$target" ]; then
            if [[ $target == */ ]]; then
                # Target is a directory, append filename
                local filename=$(basename "$key")
                aws s3 cp "s3://$bucket/$key" "$target$filename"
            else
                # Target is a full path including filename
                aws s3 cp "s3://$bucket/$key" "$target"
            fi
        else
            # No target specified, use basename of key
            local filename=$(basename "$key")
            aws s3 cp "s3://$bucket/$key" "$filename"
        fi
    fi
}

function s3-json() {
    [[ $# != 2 ]] && { echo "$0 <bucket> <key>"; return; }
    aws s3 cp s3://$1/$2 - | jq
}

function s3-head() {
    [[ $# != 2 ]] && { echo "$0 <bucket> <key>"; return; }
    aws s3api head-object --bucket $1 --key $2 | jq
}


##### SQS
function sqs() {
    aws sqs list-queues | jq -r ".QueueUrls[] | select(contains(\"$1\"))"
}

function sqs-all-attrs() {
    [[ $# != 1 ]] && { echo "$0 <queue_url>"; return; }
    aws sqs get-queue-attributes --queue-url "$1" --attribute-names All | jq
}


##### CLOUDWATCH
function ecs-metrics-ts() {
    [[ $# != 6 ]] && { echo "$0 <cluster_name> <service> <metric_required> <start_time> <end_time> <period> \nMetrics Available: all, CPUUtilization, CpuUtilized, MemoryUtilization, MemoryUtilized, RunningTaskCount\nExamples:\n$0 some-ecs-cluster some-service all 2020-09-09T14:00:19Z 2020-09-09T15:00:19Z 60\n$0 some-ecs-cluster some-service CpuUtilized 2020-09-09T14:00:19Z 2020-09-09T15:00:19Z 60"; return; }
    serviceName=`internal-ecs-get-service "$@"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return; }

    clusterName=$1
    metricRequired=$3
    period=$4
    startTime=$5
    endTime=$6

    # shellcheck disable=SC2089,SC2090
    metricsJson="[{\"Namespace\":\"AWS\/ECS\",\"MetricName\":\"CPUUtilization\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$clusterName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"ECS\/ContainerInsights\",\"MetricName\":\"CpuUtilized\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$clusterName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/ECS\",\"MetricName\":\"MemoryUtilization\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$clusterName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"ECS\/ContainerInsights\",\"MetricName\":\"MemoryUtilized\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$clusterName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"ECS\/ContainerInsights\",\"MetricName\":\"RunningTaskCount\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$clusterName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]}]"
    # shellcheck disable=SC2090
    internal-get-metric $metricsJson $metricRequired
}

function ecs-metrics() {
    [[ $# != 6 ]] && { echo "$0 <cluster_name> <service> <metric_required> <start_time> <end_time> <period> \nMetrics Available: all, CPUUtilization, CpuUtilized, MemoryUtilization, MemoryUtilized, RunningTaskCount\nExamples:\n$0 some-ecs-cluster some-service all -120M -0S 60\n$0 some-ecs-cluster some-service CpuUtilized -120M -0S 60"; return; }
    startTime=$(portable-date "$5")
    endTime=$(portable-date "$6")
    ecs-metrics-ts $1 $2 $3 $4 $startTime $endTime
}

function sqs-metrics-ts() {
    [[ $# != 5 ]] && { echo "$0 <queue_name> <metric_required> <start_time> <end_time> <period> \nMetrics Available: all, ApproximateNumberOfMessagesVisible, NumberOfMessagesSent, NumberOfMessagesReceived, ApproximateNumberOfMessagesDelayed, ApproximateAgeOfOldestMessage\nExamples:\n$0 some-sqs-queue all 2020-09-09T14:00:19Z 2020-09-09T15:00:19Z 60\n$0 some-sqs-queue NumberOfMessagesSent 2020-09-09T14:00:19Z 2020-09-09T15:00:19Z 60"; return; }
    queueName=$1
    metricRequired=$2
    period=$3
    startTime=$4
    endTime=$5

    # shellcheck disable=SC2089,SC2090
    metricsJson="[{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"ApproximateNumberOfMessagesVisible\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queueName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"NumberOfMessagesSent\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queueName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"NumberOfMessagesReceived\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queueName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"ApproximateNumberOfMessagesDelayed\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queueName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"ApproximateAgeOfOldestMessage\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queueName\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]}]"
    # shellcheck disable=SC2090
    internal-get-metric $metricsJson $metricRequired
}

function sqs-metrics() {
    [[ $# != 5 ]] && { echo "$0 <queue_name> <metric_required> <start_time> <end_time> <period> \nMetrics Available: all, ApproximateNumberOfMessagesVisible, NumberOfMessagesSent, NumberOfMessagesReceived, ApproximateNumberOfMessagesDelayed, ApproximateAgeOfOldestMessage\nExamples:\n$0 some-sqs-queue all -120M -0S 60\n$0 some-sqs-queue NumberOfMessagesSent -120M -0S 60"; return; }
    startTime=$(portable-date "$4")
    endTime=$(portable-date "$5")
    sqs-metrics-ts $1 $2 $3 $startTime $endTime
}

function db-metrics {
    name=$1
    period=$2
    startTime=$(portable-date "$3")
    endTime=$(portable-date "$4")

    # shellcheck disable=SC2089,SC2090
    metricsJson="[{\"Namespace\":\"AWS\/RDS\",\"MetricName\":\"DiskQueueDepth\",\"Dimensions\":[{\"Name\":\"DBInstanceIdentifier\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/RDS\",\"MetricName\":\"ReadIOPS\",\"Dimensions\":[{\"Name\":\"DBInstanceIdentifier\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/RDS\",\"MetricName\":\"WriteIOPS\",\"Dimensions\":[{\"Name\":\"DBInstanceIdentifier\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/RDS\",\"MetricName\":\"ReadLatency\",\"Dimensions\":[{\"Name\":\"DBInstanceIdentifier\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/RDS\",\"MetricName\":\"WriteLatency\",\"Dimensions\":[{\"Name\":\"DBInstanceIdentifier\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/RDS\",\"MetricName\":\"BurstBalance\",\"Dimensions\":[{\"Name\":\"DBInstanceIdentifier\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]}]"
    # shellcheck disable=SC2090
    internal-get-metric $metricsJson "all"
}

function elb-metrics {
    name=$1
    period=$2
    startTime=$(portable-date "$3")
    endTime=$(portable-date "$4")
    # shellcheck disable=SC2089,SC2090
    metricsJson="[{\"Namespace\":\"AWS\/ApplicationELB\",\"MetricName\":\"RequestCount\",\"Dimensions\":[{\"Name\":\"LoadBalancer\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]},{\"Namespace\":\"AWS\/ApplicationELB\",\"MetricName\":\"TargetResponseTime\",\"Dimensions\":[{\"Name\":\"LoadBalancer\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Maximum\"]},{\"Namespace\":\"AWS\/ApplicationELB\",\"MetricName\":\"HTTPCode_ELB_5XX_Count\",\"Dimensions\":[{\"Name\":\"LoadBalancer\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]},{\"Namespace\":\"AWS\/ApplicationELB\",\"MetricName\":\"HTTPCode_Target_5XX_Count\",\"Dimensions\":[{\"Name\":\"LoadBalancer\",\"Value\":\"$name\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]}]"
    # shellcheck disable=SC2090
    internal-get-metric $metricsJson "all"
}

function internal-get-metric() {
    height=15
    width=100
    metricsJson=$1
    metricRequired=$2
    i=0
    loopFlag=true
    while $loopFlag
    do
        node=`echo $metricsJson | jq ".[$i]"`
        node=`echo $node`
        if [ "$node" != "null" ]
        then
            metricName=`echo $node | jq ".MetricName" | sed -e 's/^"//' -e 's/"$//'`
            if [ "$metricRequired" = "all" ] || [ "$metricRequired" = "$metricName" ]
            then
                statistics=`echo $node | jq ".Statistics[0]" | sed -e 's/^"//' -e 's/"$//'`
                dataPoints=`echo $node | xargs -0 aws cloudwatch get-metric-statistics --cli-input-json | jq ".Datapoints"`
                echo "\t\t\t\t\t$metricName"

                # Use jp for terminal charts if available, otherwise show raw data
                if command -v jp &>/dev/null; then
                    echo $dataPoints | jp -type line -height $height -width $width -canvas braille -xy "..[Timestamp,$statistics]"
                else
                    # Fallback: display formatted JSON data
                    echo "  (Install 'jp' from https://github.com/sgreben/jp for graphical charts)"
                    echo $dataPoints | jq -r ".[] | \"\(.Timestamp): \(.$statistics)\""
                fi
                echo "\n\n"
            fi

            i=`expr $i + 1`
        else
            loopFlag=false
        fi
    done
}
