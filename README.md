
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
- `splunk_ingest_url`: Find the real-time data ingest URL in Profile > Account Settings > Endpoints. Note: do NOT include endpoint path here: for instance use https://ingest.us1.signalfx.com instead of https://ingest.us1.signalfx.com/v1/cloudwatch_metric_stream.
- `AWS_REGION`: AWS Region where the resources will be created.

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
    splunk_access_token = "your-splunk-access-token"
    splunk_ingest_url   = "your-splunk-ingest-url"
    AWS_REGION          = "your-aws-region"
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

