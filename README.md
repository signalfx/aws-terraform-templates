
# Terraform Setup for Creating Kinesis Firehose to Send CloudWatch Metric Stream

This Terraform setup allows you to create a Kinesis Firehose delivery stream to send CloudWatch metric data. This README provides an overview of the files included in this repository and instructions on how to use them.

## Prerequisites

Before you begin, ensure you have the following:

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- AWS credentials configured with the necessary permissions to create resources.

## Files

- `variables.tf`: Contains the variable declarations used in the Terraform configuration.
- `main.tf`: Contains the main Terraform configuration for creating the Kinesis Firehose delivery stream.

## Variables

The following variables can be supplied via a `.tfvars` file:

- `splunk_access_token`: Copy your Splunk Observability access token with INGEST authorization scope from Settings > Access Tokens.
- `splunk_ingest_url`: Copy the Real-time Data Ingest Endpoint value from My Profile > Organizations.
- `AWS_REGION`: AWS Region where the resources will be created.
- `enable_server_side_encryption` (optional, default `false`): Enable server-side encryption (SSE) at rest on the Kinesis Data Firehose delivery stream.
- `firehose_encryption_key_arn` (optional, default `""`): ARN of an existing customer-managed KMS key to use for delivery stream encryption. Leave blank to use an AWS-owned key or to create a new key (see `create_encryption_key`). Only applies when `enable_server_side_encryption` is `true`. See [Using an existing KMS key](#using-an-existing-kms-key) for the requirements that key must meet.
- `create_encryption_key` (optional, default `false`): Create a new customer-managed KMS key for delivery stream encryption. Only applies when `enable_server_side_encryption` is `true` and `firehose_encryption_key_arn` is left blank.

### Using an existing KMS key

The existing key must:

- be a **symmetric** key (Firehose does not support asymmetric CMKs);
- be in the **same region** as the delivery stream;
- have a key policy that allows the producer role (`splunk-metric-streams-<region>`) `kms:GenerateDataKey` and `kms:Decrypt` (required for data writes); and
- have a key policy that allows the `firehose.amazonaws.com` service principal `kms:CreateGrant` (required during stream creation / when encryption is started).

If you instead set `create_encryption_key = true`, the key created by this configuration already includes all of the above.

#### Sample KMS key policy

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "EnableIAMUserPermissions",
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::${local.account_id}:root"
			},
			"Action": "kms:*",
			"Resource": "*"
		},
		{
			"Sid": "AllowFirehoseUseOfTheKey",
			"Effect": "Allow",
			"Principal": {
				"Service": "firehose.amazonaws.com"
			},
			"Action": [
				"kms:GenerateDataKey",
				"kms:Decrypt"
			],
			"Resource": "*",
			"Condition": {
				"StringEquals": {
					"kms:CallerAccount": "${local.account_id}",
					"kms:ViaService": "firehose.${var.AWS_REGION}.amazonaws.com"
				}
			}
		},
		{
			"Sid": "AllowFirehoseToCreateGrants",
			"Effect": "Allow",
			"Principal": {
				"Service": "firehose.amazonaws.com"
			},
			"Action": "kms:CreateGrant",
			"Resource": "*",
			"Condition": {
				"StringEquals": {
					"kms:CallerAccount": "${local.account_id}",
					"kms:ViaService": "firehose.${var.AWS_REGION}.amazonaws.com"
				},
				"Bool": {
					"kms:GrantIsForAWSResource": "true"
				}
			}
		}
	]
}
```

## Usage

1. Clone this repository to your local machine:

    ```bash
    git clone <repository-url>
    ```

2. Navigate to the cloned directory:

    ```bash
    cd <repository-directory>
    ```

3. Create a file named `terraform.tfvars` and provide values for the variables:

    ```hcl
    splunk_access_token           = "your-splunk-access-token"
    splunk_ingest_url             = "your-splunk-ingest-url"
    AWS_REGION                    = "your-aws-region"
    enable_server_side_encryption = false
    firehose_encryption_key_arn   = ""
    create_encryption_key         = false
    ```

4. Initialize Terraform:

    ```bash
    terraform init
    ```

5. Review the Terraform execution plan:

    ```bash
    terraform plan
    ```

6. Apply the Terraform configuration to create the Kinesis Firehose delivery stream:

    ```bash
    terraform apply
    ```

7. Confirm the action by typing `yes` when prompted.

8. Once Terraform has successfully applied the configuration, the Kinesis Firehose delivery stream will be created in your AWS account.

## Cleanup

To avoid incurring unnecessary costs, you can destroy the resources created by Terraform when they are no longer needed. To do this, run:

```bash
terraform destroy
```

## Output

After successfully applying the Terraform configuration, you will see the following resources created in your AWS account:

- **S3 Bucket**: A bucket named `splunk-metric-streams-s3-{account_id}-{region}` will be created to store data processed by the Kinesis Firehose delivery stream.

- **CloudWatch Log Group**: A log group named `/aws/kinesisfirehose/splunk-metric-streams-{region}` will be created to capture logs related to the Kinesis Firehose delivery stream.

- **IAM Role for S3**: An IAM role named `splunk-metric-streams-s3-{region}` will be created with permissions for the Kinesis Firehose to access the S3 bucket and CloudWatch Logs.

- **Kinesis Firehose Delivery Stream**: A Kinesis Firehose delivery stream named `splunk-metric-streams-{region}` will be created with configurations to send data to Splunk via HTTP endpoint and store backup data in the S3 bucket.

- **IAM Role for Metric Streams**: An IAM role named `splunk-metric-streams-{region}` will be created with permissions for CloudWatch MetricStreams to publish data to the Kinesis Firehose delivery stream.

