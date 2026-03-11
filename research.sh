#!/bin/bash

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

CloudTrail イベント検索スクリプト

OPTIONS:
  -k <key>      Lookup attribute key (default: EventSource)
                Available keys: EventId, EventName, ReadOnly, Username,
                               ResourceType, ResourceName, EventSource, AccessKeyId
  -v <values>   Lookup attribute values (space-separated, default: "iam.amazonaws.com ec2.amazonaws.com")
  -r <regions>  Target regions (space-separated, default: all enabled regions)
  -s <days>     Start time in days ago (default: 2)
  -o <prefix>   Output file prefix (default: uses first part of attribute value)
  -p <profile>  AWS CLI profile name (default: default profile)
  -h            Show this help message

EXAMPLES:
  # EventSource で検索 (全リージョン)
  $0 -k EventSource -v "iam.amazonaws.com ec2.amazonaws.com"

  # EventName で検索 (ap-northeast-1 のみ)
  $0 -k EventName -v "RunInstances TerminateInstances" -r "ap-northeast-1"

  # Username で検索 (複数リージョン指定)
  $0 -k Username -v "admin user123" -r "us-east-1 ap-northeast-1"

  # AccessKeyId で検索
  $0 -k AccessKeyId -v "AKIAIOSFODNN7EXAMPLE"

EOF
}

# デフォルト値
ATTRIBUTE_KEY="EventSource"
ATTRIBUTE_VALUES="iam.amazonaws.com ec2.amazonaws.com"
DAYS_AGO=2
OUTPUT_PREFIX=""
REGIONS=""
PROFILE=""

# オプション解析
while getopts "k:v:r:s:o:p:h" opt; do
  case $opt in
    k) ATTRIBUTE_KEY=$OPTARG ;;
    v) ATTRIBUTE_VALUES=$OPTARG ;;
    r) REGIONS=$OPTARG ;;
    s) DAYS_AGO=$OPTARG ;;
    o) OUTPUT_PREFIX=$OPTARG ;;
    p) PROFILE=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# 日付計算
if date -v-1d &>/dev/null; then
  START=$(date -v-${DAYS_AGO}d +%s)
else
  START=$(date -d "$DAYS_AGO days ago" +%s)
fi
END=$(date +%s)

# リージョン設定（指定がなければ全リージョンを取得）
if [ -z "$REGIONS" ]; then
  REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text ${PROFILE:+--profile "$PROFILE"})
  echo "Target: All enabled regions"
else
  echo "Target: Specified regions - $REGIONS"
fi

[ -n "$PROFILE" ] && echo "Profile: $PROFILE"

echo "Search parameters:"
echo "  AttributeKey: $ATTRIBUTE_KEY"
echo "  AttributeValues: $ATTRIBUTE_VALUES"
echo "  Start time: $(date -d @${START} 2>/dev/null || date -r ${START})"
echo "  End time: $(date -d @${END} 2>/dev/null || date -r ${END})"
echo ""

for VALUE in $ATTRIBUTE_VALUES; do
  # プレフィックスの決定
  if [ -n "$OUTPUT_PREFIX" ]; then
    PREFIX="${OUTPUT_PREFIX}"
  else
    # 値から適切なプレフィックスを生成
    if [[ "$VALUE" == *.amazonaws.com ]]; then
      PREFIX=$(echo $VALUE | cut -d. -f1)
    else
      PREFIX=$(echo $VALUE | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')
    fi
  fi

  OUTPUT_FILE="${PREFIX}_${ATTRIBUTE_KEY}_output.csv"

  echo "Processing: $ATTRIBUTE_KEY = $VALUE"
  echo "  Output: $OUTPUT_FILE"

  > "$OUTPUT_FILE"
  echo "EventTime,EventName,Username,SourceIPAddress,UserAgent,errorCode,errorMessage,Region" >> "$OUTPUT_FILE"

  for REGION in $REGIONS; do
    echo "  Region: $REGION"
    aws cloudtrail lookup-events \
      --start-time ${START} \
      --end-time ${END} \
      --region ${REGION} \
      --lookup-attributes AttributeKey="${ATTRIBUTE_KEY}",AttributeValue="${VALUE}" \
      ${PROFILE:+--profile "$PROFILE"} \
    | jq -r --arg region "$REGION" '
      .Events[] |= (.CloudTrailEvent |= fromjson)
      | .Events[]
      | [.EventTime, .EventName, .Username, .CloudTrailEvent.sourceIPAddress, .CloudTrailEvent.userAgent, .CloudTrailEvent.errorCode, .CloudTrailEvent.errorMessage, $region]
      | @csv
    ' >> "$OUTPUT_FILE"
  done

  echo "Completed: $OUTPUT_FILE"
  echo ""
done
