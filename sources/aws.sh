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

# Convert a `-s`/`-e` value to an absolute ISO timestamp.
# Offsets start with `-` (e.g. -2H, -0S) and go through portable-date;
# anything else (e.g. 2020-09-09T14:00:19Z) is passed through unchanged.
function _maybe_portable_date() {
    local val=$1
    if [[ "$val" == -* ]]; then
        portable-date "$val"
    else
        echo "$val"
    fi
}

# Map short metric aliases to their CloudWatch metric names.
# Unknown values pass through unchanged so full names still work.
function _resolve_metric_alias() {
    case "$1" in
        cpu)      echo "CPUUtilization" ;;
        cpu-used) echo "CpuUtilized" ;;
        mem)      echo "MemoryUtilization" ;;
        mem-used) echo "MemoryUtilized" ;;
        tasks)    echo "RunningTaskCount" ;;
        msgs)     echo "ApproximateNumberOfMessagesVisible" ;;
        sent)     echo "NumberOfMessagesSent" ;;
        received) echo "NumberOfMessagesReceived" ;;
        delayed)  echo "ApproximateNumberOfMessagesDelayed" ;;
        age)      echo "ApproximateAgeOfOldestMessage" ;;
        *)        echo "$1" ;;
    esac
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

##### EC2
# List EC2 instances (name, ID, launch time), sorted by launch time.
function ec2-instances {
    aws ec2 describe-instances \
        --query 'sort_by(Reservations[].Instances[].{Name: Tags[?Key==`Name`]|[0].Value, ID: InstanceId, Launched: LaunchTime}, &Launched)' \
        --output table
}


##### ECS
function ecs-clusters {
    aws ecs list-clusters --output json | jq -r ".clusterArns[] | select(contains(\"$1\"))"
}

function ecs-services {
    local cluster
    case $# in
        1) cluster=$1 ;;
        0) cluster=$AWS_ECS_CLUSTER ;;
        *) echo "Usage: $0 [cluster]  (set AWS_ECS_CLUSTER to omit)"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    aws ecs list-services --cluster "$cluster" --output json
}

function internal-ecs-get-service {
    serviceFilter=`echo "$2[a-zA-Z0-9\-]*"`
    echo `aws ecs list-services --cluster $1 | grep -o $serviceFilter`
}

function ecs-service {
    local cluster service
    case $# in
        2) cluster=$1; service=$2 ;;
        1) cluster=$AWS_ECS_CLUSTER; service=$1 ;;
        *) echo "Usage: $0 [cluster] <service>  (set AWS_ECS_CLUSTER to omit cluster)"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    internal-ecs-describe-service "serviceOnly" "$cluster" "$service"
}

function ecs-service-events {
    local cluster service count
    case $# in
        3) cluster=$1; service=$2; count=$3 ;;
        2) cluster=$AWS_ECS_CLUSTER; service=$1; count=$2 ;;
        *) echo "Usage: $0 [cluster] <service> <num_events>"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    internal-ecs-describe-service "serviceEventsOnly" "$cluster" "$service" "$count"
}

function ecs-service-task-definition {
    local cluster service
    case $# in
        2) cluster=$1; service=$2 ;;
        1) cluster=$AWS_ECS_CLUSTER; service=$1 ;;
        *) echo "Usage: $0 [cluster] <service>"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    internal-ecs-describe-service "taskDefinition" "$cluster" "$service"
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
    local cluster service
    case $# in
        2) cluster=$1; service=$2 ;;
        1) cluster=$AWS_ECS_CLUSTER; service=$1 ;;
        *) echo "Usage: $0 [cluster] <service>"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }

    serviceName=`internal-ecs-get-service "$cluster" "$service"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return 1; }
    serviceDesc=`aws ecs describe-services --cluster "$cluster" --service "$serviceName"`
    echo ">>> Service"
    echo $serviceDesc | jq

    tdFilter=`echo "$service:[0-9]*"`
    taskDefinition=`echo $serviceDesc | jq ".services[].taskDefinition" | grep -o $tdFilter`
    taskDefinitionDesc=`aws ecs describe-task-definition --task-definition $taskDefinition`
    echo ">>> Task Definition"
    echo $taskDefinitionDesc | jq
}

function ecs-force-deploy {
    local cluster service
    case $# in
        2) cluster=$1; service=$2 ;;
        1) cluster=$AWS_ECS_CLUSTER; service=$1 ;;
        *) echo "Usage: $0 [cluster] <service>"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    serviceName=`internal-ecs-get-service "$cluster" "$service"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return 1; }
    aws ecs update-service --cluster "$cluster" --service "$serviceName" --force-new-deployment | jq ".service | {serviceName, status, desiredCount, runningCount, pendingCount, launchType, taskDefinition, clusterArn, loadBalancers, roleArn}"
}

function ecs-set-desired-count {
    local cluster service count
    case $# in
        3) cluster=$1; service=$2; count=$3 ;;
        2) cluster=$AWS_ECS_CLUSTER; service=$1; count=$2 ;;
        *) echo "Usage: $0 [cluster] <service> <num_of_instances>"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    serviceName=`internal-ecs-get-service "$cluster" "$service"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return 1; }
    aws ecs update-service --cluster "$cluster" --service "$serviceName" --desired-count "$count" | jq ".service | {serviceName, status, desiredCount, runningCount, pendingCount, launchType, taskDefinition, clusterArn, loadBalancers, roleArn}"
}

# List running tasks for a service (task id, status, health, start time).
function ecs-tasks {
    local cluster service
    case $# in
        2) cluster=$1; service=$2 ;;
        1) cluster=$AWS_ECS_CLUSTER; service=$1 ;;
        *) echo "Usage: $0 [cluster] <service>"; return 1 ;;
    esac
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    serviceName=`internal-ecs-get-service "$cluster" "$service"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return 1; }

    # Newline-separated ARNs piped through xargs, so this works whether the
    # function is sourced into bash or zsh (zsh doesn't word-split "$taskArns").
    taskArns=`aws ecs list-tasks --cluster "$cluster" --service-name "$serviceName" --output json | jq -r '.taskArns[]'`
    [ -z "$taskArns" ] && { echo "no running tasks for $serviceName"; return; }
    echo "$taskArns" | xargs aws ecs describe-tasks --output json --cluster "$cluster" --tasks | \
        jq -r '.tasks[] | "\(.taskArn|split("/")[-1])\t\(.lastStatus)\t\(.healthStatus)\t\(.startedAt // "n/a")"'
}

# Tail the CloudWatch logs for a service. Live tail by default; pass a
# duration (e.g. 15m, 1h) as the third argument for a recent snapshot.
function ecs-logs {
    local cluster service since
    case $# in
        2|3) cluster=$1; service=$2; since=$3 ;;
        1)   cluster=$AWS_ECS_CLUSTER; service=$1 ;;
        *)
            echo "Usage: $0 [cluster] <service> [since]"
            echo "  since: omit for live tail (--follow); pass a duration (e.g. 15m, 1h) for a recent snapshot"
            echo "Examples:"
            echo "  $0 some-ecs-cluster some-service        # live tail"
            echo "  $0 some-ecs-cluster some-service 15m    # last 15 minutes"
            echo "  $0 some-service                         # with AWS_ECS_CLUSTER set"
            return 1
            ;;
    esac
    # Special case: 2 args + env set could mean (service, since) instead of (cluster, service).
    # Disambiguate: if cluster (=$1) doesn't look like a duration and env is set,
    # treat $1 as service and $2 as since.
    if [[ $# -eq 2 && -n "$AWS_ECS_CLUSTER" && "$2" =~ ^[0-9]+[smhd]$ ]]; then
        cluster=$AWS_ECS_CLUSTER
        service=$1
        since=$2
    fi
    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }

    serviceName=`internal-ecs-get-service "$cluster" "$service"`
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return 1; }

    taskDefinition=`aws ecs describe-services --cluster "$cluster" --service "$serviceName" --output json | jq -r '.services[0].taskDefinition'`
    { [ -z "$taskDefinition" ] || [ "$taskDefinition" = "null" ]; } && { echo "task definition not found"; return 1; }

    logGroup=`aws ecs describe-task-definition --task-definition "$taskDefinition" --output json | \
        jq -r '[.taskDefinition.containerDefinitions[].logConfiguration.options."awslogs-group"] | map(select(. != null)) | unique | .[0]'`
    { [ -z "$logGroup" ] || [ "$logGroup" = "null" ]; } && { echo "no awslogs log group configured for this service"; return 1; }

    echo "log group :: $logGroup"
    if [ -n "$since" ]; then
        aws logs tail "$logGroup" --since "$since" --format short
    else
        aws logs tail "$logGroup" --since 1m --follow --format short
    fi
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
    [[ $# -lt 1 ]] && {
        echo "Usage: $0 <input_json_file> [options]"
        echo "Options:"
        echo "  -n, --name <param_name>  Update only the specified parameter"
        echo "  -k, --key-id <key_id>    Use specified KMS key (default: alias/aws/ssm)"
        return 1
    }

    local inputFile="" targetName="" keyId="alias/aws/ssm"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)   targetName="$2"; shift 2 ;;
            -k|--key-id) keyId="$2";      shift 2 ;;
            *)           inputFile="$1";  shift   ;;
        esac
    done

    [[ -z "$inputFile" ]] && { echo "Error: Input file is required"; return 1; }

    while IFS= read -r param; do
        local name type newValue node
        name=$(echo "$param" | jq -r '.Name')
        type=$(echo "$param" | jq -r '.Type')
        newValue=$(echo "$param" | jq -r '.Value')

        [[ -n "$targetName" && "$targetName" != "$name" ]] && continue

        if [[ "$type" == "SecureString" ]]; then
            node=$(echo "$param" | jq -c --arg kid "$keyId" '{Name, Type, Value} + {KeyId: $kid}')
        else
            node=$(echo "$param" | jq -c '{Name, Type, Value}')
        fi

        local oldVersion=0 oldValue="" newVersion result
        if result=$(aws ssm get-parameter --name "$name" --with-decryption 2>/dev/null); then
            oldVersion=$(echo "$result" | jq -r '.Parameter.Version')
            oldValue=$(echo "$result" | jq -r '.Parameter.Value')

            if [[ "$oldValue" == "$newValue" ]]; then
                echo "ssm parameter :: $name"
                echo -e "\tvalue unchanged (version: $oldVersion)"
            else
                newVersion=$(aws ssm put-parameter --cli-input-json "$node" --overwrite --output json | jq '.Version')
                echo "ssm put-parameter :: $name"
                echo -e "\tvalue: $oldValue -> $newValue"
                echo -e "\tversion: $oldVersion -> $newVersion"
            fi
        else
            newVersion=$(aws ssm put-parameter --cli-input-json "$node" --output json | jq '.Version')
            echo "ssm put-parameter :: $name"
            echo -e "\tvalue: (new parameter) -> $newValue"
            echo -e "\tversion: 0 -> $newVersion"
        fi

        [[ -n "$targetName" ]] && break
    done < <(jq -c '.Parameters[]' "$inputFile")
}

function ssm-delete-params() {
    [[ $# != 1 ]] && { echo "Usage: $0 <input_json_file>"; return 1; }
    local inputFile=$1
    jq -r '.Parameters[].Name' "$inputFile" | while IFS= read -r name; do
        aws ssm delete-parameter --name "$name" 2>/dev/null \
            && echo "ssm delete-parameter :: $name" \
            || echo "ssm delete-parameter :: $name (not found, skipped)"
    done
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

# Show CloudWatch metrics charts for an ECS service.
# Usage: ecs-metrics [-c cluster] [-m metric] [-s since] [-e end] [-p period] <service>
#   --since / --end accept offsets (-2H, -120M, -0S) or ISO timestamps.
function ecs-metrics() {
    local cluster=$AWS_ECS_CLUSTER service metric=all
    local since=-1H end=-0S period=60

    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--cluster) cluster=$2; shift 2 ;;
            -m|--metric)  metric=$(_resolve_metric_alias "$2"); shift 2 ;;
            -s|--since)   since=$2; shift 2 ;;
            -e|--end)     end=$2; shift 2 ;;
            -p|--period)  period=$2; shift 2 ;;
            -h|--help)
                cat <<EOF
Usage: ecs-metrics [opts] <service>
  -c, --cluster <name>   ECS cluster (default: \$AWS_ECS_CLUSTER)
  -m, --metric <name>    Metric or alias (default: all)
                         aliases: cpu, cpu-used, mem, mem-used, tasks
                         full:    CPUUtilization, CpuUtilized,
                                  MemoryUtilization, MemoryUtilized,
                                  RunningTaskCount
  -s, --since <when>     Start (default: -1H). Offset like -2H or ISO timestamp.
  -e, --end <when>       End   (default: -0S). Same format as --since.
  -p, --period <secs>    Period in seconds (default: 60)

Examples:
  ecs-metrics my-svc                          # all metrics, last hour
  ecs-metrics my-svc -m cpu -s -2H            # CPU over last 2 hours
  ecs-metrics -c my-cluster my-svc -m mem
  ecs-metrics my-svc -s 2020-09-09T14:00:19Z -e 2020-09-09T15:00:19Z
EOF
                return 0
                ;;
            -*) echo "Unknown option: $1" >&2; return 1 ;;
            *)  service=$1; shift ;;
        esac
    done

    [[ -z "$cluster" ]] && { echo "Error: cluster not given and AWS_ECS_CLUSTER not set" >&2; return 1; }
    [[ -z "$service" ]] && { echo "Error: service required (try -h)" >&2; return 1; }

    local startTime endTime
    startTime=$(_maybe_portable_date "$since") || return 1
    endTime=$(_maybe_portable_date "$end") || return 1

    local serviceName
    serviceName=$(internal-ecs-get-service "$cluster" "$service")
    [ -z "$serviceName" ] && { echo "service not found in the cluster"; return 1; }

    # shellcheck disable=SC2089,SC2090
    local metricsJson="[{\"Namespace\":\"AWS\/ECS\",\"MetricName\":\"CPUUtilization\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$cluster\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"ECS\/ContainerInsights\",\"MetricName\":\"CpuUtilized\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$cluster\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/ECS\",\"MetricName\":\"MemoryUtilization\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$cluster\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"ECS\/ContainerInsights\",\"MetricName\":\"MemoryUtilized\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$cluster\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"ECS\/ContainerInsights\",\"MetricName\":\"RunningTaskCount\",\"Dimensions\":[{\"Name\":\"ServiceName\",\"Value\":\"$serviceName\"},{\"Name\":\"ClusterName\",\"Value\":\"$cluster\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]}]"
    # shellcheck disable=SC2090
    internal-get-metric $metricsJson $metric
}

# Kept for muscle memory; ecs-metrics now accepts absolute timestamps via -s/-e.
function ecs-metrics-ts() { ecs-metrics "$@"; }

# Show CloudWatch metrics charts for an SQS queue.
# Usage: sqs-metrics [-m metric] [-s since] [-e end] [-p period] <queue>
function sqs-metrics() {
    local queue metric=all
    local since=-1H end=-0S period=60

    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--metric)  metric=$(_resolve_metric_alias "$2"); shift 2 ;;
            -s|--since)   since=$2; shift 2 ;;
            -e|--end)     end=$2; shift 2 ;;
            -p|--period)  period=$2; shift 2 ;;
            -h|--help)
                cat <<EOF
Usage: sqs-metrics [opts] <queue>
  -m, --metric <name>    Metric or alias (default: all)
                         aliases: msgs, sent, received, delayed, age
                         full:    ApproximateNumberOfMessagesVisible,
                                  NumberOfMessagesSent, NumberOfMessagesReceived,
                                  ApproximateNumberOfMessagesDelayed,
                                  ApproximateAgeOfOldestMessage
  -s, --since <when>     Start (default: -1H)
  -e, --end <when>       End   (default: -0S)
  -p, --period <secs>    Period in seconds (default: 60)

Examples:
  sqs-metrics my-queue
  sqs-metrics my-queue -m sent -s -2H
EOF
                return 0
                ;;
            -*) echo "Unknown option: $1" >&2; return 1 ;;
            *)  queue=$1; shift ;;
        esac
    done

    [[ -z "$queue" ]] && { echo "Error: queue required (try -h)" >&2; return 1; }

    local startTime endTime
    startTime=$(_maybe_portable_date "$since") || return 1
    endTime=$(_maybe_portable_date "$end") || return 1

    # shellcheck disable=SC2089,SC2090
    local metricsJson="[{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"ApproximateNumberOfMessagesVisible\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queue\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"NumberOfMessagesSent\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queue\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"NumberOfMessagesReceived\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queue\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Sum\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"ApproximateNumberOfMessagesDelayed\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queue\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]},{\"Namespace\":\"AWS\/SQS\",\"MetricName\":\"ApproximateAgeOfOldestMessage\",\"Dimensions\":[{\"Name\":\"QueueName\",\"Value\":\"$queue\"}],\"StartTime\":\"$startTime\",\"EndTime\":\"$endTime\",\"Period\":$period,\"Statistics\":[\"Average\"]}]"
    # shellcheck disable=SC2090
    internal-get-metric $metricsJson $metric
}

function sqs-metrics-ts() { sqs-metrics "$@"; }

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

##### ECS DISPATCHER
# Single entry point: `ecs <subcommand> [args...]`. All ecs-* functions still
# work directly; this is an additive convenience. Cluster is optional in most
# subcommands when AWS_ECS_CLUSTER is set.
function ecs() {
    local subcmd=$1
    [[ $# -gt 0 ]] && shift
    case "$subcmd" in
        clusters) ecs-clusters "$@" ;;
        services) ecs-services "$@" ;;
        service)  ecs-service "$@" ;;
        events)   ecs-service-events "$@" ;;
        td)       ecs-service-task-definition "$@" ;;
        info)     ecs-service-complete "$@" ;;
        deploy)   ecs-force-deploy "$@" ;;
        scale)    ecs-set-desired-count "$@" ;;
        tasks)    ecs-tasks "$@" ;;
        logs)     ecs-logs "$@" ;;
        metrics)  ecs-metrics "$@" ;;
        ""|-h|--help|help)
            cat <<EOF
Usage: ecs <subcommand> [args...]

Subcommands:
  clusters [pattern]                List ECS clusters (optional substring filter)
  services [cluster]                List services in cluster
  service  [cluster] <service>      Describe a service
  events   [cluster] <service> <n>  Show last n service events
  td       [cluster] <service>      Show task definition for service
  info     [cluster] <service>      Full service + task definition dump
  deploy   [cluster] <service>      Force a new deployment
  scale    [cluster] <service> <n>  Set desired count
  tasks    [cluster] <service>      List running tasks
  logs     [cluster] <service> [since]   Tail CloudWatch logs
  metrics  [opts] <service>         Metrics charts (see: ecs metrics -h)

Set AWS_ECS_CLUSTER to omit [cluster] from any subcommand.
EOF
            ;;
        *) echo "Unknown ecs subcommand: $subcmd (try: ecs help)" >&2; return 1 ;;
    esac
}
