> English follows Japanese.

# CloudTrail イベント検索スクリプト

AWS CloudTrail のイベントを検索し、CSV形式で出力するスクリプトです。

## 機能

- CloudTrail の lookup-attributes に対応した柔軟な検索が可能
- 複数のリージョンを一括検索（全リージョン or 指定リージョン）可能
- 複数の検索値を同時処理が可能
- CSV形式での出力（時刻、イベント名、ユーザー名、IPアドレスなど）

## 必要な環境

- AWS CLI がインストール・設定済みであること
- `jq` コマンドがインストールされていること
- CloudTrail の読み取り権限があること
- ec2:DescribeRegions の権限があること

## ライセンス

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 使い方

```bash
./research.sh [OPTIONS]
```

### オプション

| オプション | 説明 | デフォルト値 |
|----------|------|------------|
| `-k <key>` | Lookup attribute key | `EventSource` |
| `-v <values>` | 検索する値（スペース区切りで複数指定可） | `iam.amazonaws.com ec2.amazonaws.com` |
| `-r <regions>` | 対象リージョン（スペース区切りで複数指定可） | 全有効リージョン |
| `-s <days>` | 何日前から検索するか | `2` |
| `-o <prefix>` | 出力ファイルのプレフィックス | 自動生成 |
| `-p <profile>` | AWS CLI プロファイル名 | デフォルトプロファイル |
| `-h` | ヘルプメッセージを表示 | - |

### 利用可能な Lookup Attribute Keys

- `EventId` - 特定のイベントIDで検索
- `EventName` - イベント名で検索（例: RunInstances, TerminateInstances）
- `ReadOnly` - 読み取り専用操作かどうか（true/false）
- `Username` - IAMユーザー名で検索
- `ResourceType` - リソースタイプで検索
- `ResourceName` - リソース名で検索
- `EventSource` - AWSサービスで検索（例: ec2.amazonaws.com）
- `AccessKeyId` - アクセスキーIDで検索

## 使用例

### 1. デフォルト実行（全リージョンで EventSource を検索）

```bash
./research.sh
```

IAM と EC2 のイベントを過去2日分、全リージョンから検索します。

### 2. 特定のイベント名を検索

```bash
./research.sh -k EventName -v "RunInstances TerminateInstances"
```

EC2 インスタンスの起動・終了イベントを検索します。

### 3. 特定リージョンのみで検索

```bash
./research.sh -k EventSource -v "s3.amazonaws.com" -r "ap-northeast-1"
```

東京リージョンのみで S3 のイベントを検索します。

### 4. 複数リージョンを指定して検索

```bash
./research.sh -k Username -v "admin" -r "us-east-1 ap-northeast-1 eu-west-1"
```

3つのリージョンで特定ユーザーのイベントを検索します。

### 5. 過去7日間のデータを検索

```bash
./research.sh -k EventSource -v "lambda.amazonaws.com" -s 7
```

Lambda のイベントを過去7日分検索します。

### 6. アクセスキーIDで検索

```bash
./research.sh -k AccessKeyId -v "AKIAIOSFODNN7EXAMPLE" -r "us-east-1"
```

特定のアクセスキーの使用履歴を検索します。

### 7. 特定のAWSプロファイルを使用して検索

```bash
./research.sh -p production -k EventSource -v "iam.amazonaws.com"
```

`production` という名前のAWS CLIプロファイルを使用して検索します。

### 8. プロファイルとリージョンを組み合わせて検索

```bash
./research.sh -p dev -k EventName -v "RunInstances" -r "ap-northeast-1" -s 7
```

`dev` プロファイルを使用して、東京リージョンで過去7日間のEC2起動イベントを検索します。

## 出力ファイル

実行すると、以下の形式でCSVファイルが生成されます：

```
<prefix>_<AttributeKey>_output.csv
```

例：
- `iam_EventSource_output.csv`
- `runinstances_EventName_output.csv`
- `admin_Username_output.csv`

### CSVファイルの列

| 列名 | 説明 |
|-----|------|
| EventTime | イベント発生時刻 |
| EventName | イベント名 |
| Username | IAMユーザー名 |
| SourceIPAddress | 送信元IPアドレス |
| UserAgent | ユーザーエージェント |
| errorCode | エラーコード（ある場合） |
| errorMessage | エラーメッセージ（ある場合） |
| Region | リージョン名 |

## 注意事項

- CloudTrail は最大90日間のイベント履歴を保持します
- 大量のイベントがある場合、検索に時間がかかる場合があります
- リージョンごとに API コールが発生するため、全リージョン検索は時間がかかります
- AWS API の Rate Limit に注意してください

## トラブルシューティング

### AWS CLI が見つからない

```bash
# AWS CLI のインストール確認
aws --version

# インストールされていない場合
# macOS
brew install awscli

# Linux
pip install awscli
```

### jq が見つからない

```bash
# jq のインストール
# macOS
brew install jq

# Linux
sudo apt-get install jq
# または
sudo yum install jq
```

### 権限エラーが発生する

スクリプトに実行権限を付与してください：

```bash
chmod +x research.sh
```

AWS の権限を確認してください：
- `cloudtrail:LookupEvents` 権限が必要です
- `ec2:DescribeRegions` 権限が必要です




---

# CloudTrail Event Search Script

A script that searches AWS CloudTrail events and outputs the results in CSV format.

## Features

- Flexible searching using CloudTrail's lookup-attributes
- Bulk search across multiple regions (all regions or specific ones)
- Process multiple search values at once
- CSV output (timestamp, event name, username, IP address, etc.)

## Prerequisites

- AWS CLI installed and configured
- `jq` command installed
- CloudTrail read permissions
- ec2:DescribeRegions permission

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Usage

```bash
./research.sh [OPTIONS]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-k <key>` | Lookup attribute key | `EventSource` |
| `-v <values>` | Values to search for (space-separated for multiple values) | `iam.amazonaws.com ec2.amazonaws.com` |
| `-r <regions>` | Target regions (space-separated for multiple regions) | All enabled regions |
| `-s <days>` | How many days back to search | `2` |
| `-o <prefix>` | Output file prefix | Auto-generated |
| `-h` | Show help message | - |

### Available Lookup Attribute Keys

- `EventId` — Search by a specific event ID
- `EventName` — Search by event name (e.g., RunInstances, TerminateInstances)
- `ReadOnly` — Filter by read-only operations (true/false)
- `Username` — Search by IAM username
- `ResourceType` — Search by resource type
- `ResourceName` — Search by resource name
- `EventSource` — Search by AWS service (e.g., ec2.amazonaws.com)
- `AccessKeyId` — Search by access key ID

## Examples

### 1. Default run (search EventSource across all regions)

```bash
./research.sh
```

Searches for IAM and EC2 events from the past 2 days across all regions.

### 2. Search for specific event names

```bash
./research.sh -k EventName -v "RunInstances TerminateInstances"
```

Searches for EC2 instance launch and termination events.

### 3. Search in a specific region only

```bash
./research.sh -k EventSource -v "s3.amazonaws.com" -r "ap-northeast-1"
```

Searches for S3 events in the Tokyo region only.

### 4. Search across multiple specified regions

```bash
./research.sh -k Username -v "admin" -r "us-east-1 ap-northeast-1 eu-west-1"
```

Searches for a specific user's events across three regions.

### 5. Search the past 7 days

```bash
./research.sh -k EventSource -v "lambda.amazonaws.com" -s 7
```

Searches for Lambda events from the past 7 days.

### 6. Search by access key ID

```bash
./research.sh -k AccessKeyId -v "AKIAIOSFODNN7EXAMPLE" -r "us-east-1"
```

Searches for usage history of a specific access key.

## Output Files

The script generates CSV files in the following format:

```
<prefix>_<AttributeKey>_output.csv
```

Examples:
- `iam_EventSource_output.csv`
- `runinstances_EventName_output.csv`
- `admin_Username_output.csv`

### CSV Columns

| Column | Description |
|--------|-------------|
| EventTime | When the event occurred |
| EventName | Name of the event |
| Username | IAM username |
| SourceIPAddress | Source IP address |
| UserAgent | User agent string |
| errorCode | Error code (if any) |
| errorMessage | Error message (if any) |
| Region | Region name |

## Notes

- CloudTrail retains up to 90 days of event history
- Searches may take a while if there are a large number of events
- An API call is made for each region, so searching all regions takes time
- Be mindful of AWS API rate limits

## Troubleshooting

### AWS CLI not found

```bash
# Check if AWS CLI is installed
aws --version

# If not installed:
# macOS
brew install awscli

# Linux
pip install awscli
```

### jq not found

```bash
# Install jq
# macOS
brew install jq

# Linux
sudo apt-get install jq
# or
sudo yum install jq
```

### Permission errors

Make sure the script has execute permissions:

```bash
chmod +x research.sh
```

Verify your AWS permissions:
- `cloudtrail:LookupEvents` is required
- `ec2:DescribeRegions` is required
