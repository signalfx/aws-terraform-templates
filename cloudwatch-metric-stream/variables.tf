variable "splunk_access_token" {
  description = "Copy your Splunk Observability access token with INGEST authorization scope from Settings > Access Tokens."
  type        = string
}

variable "splunk_ingest_url" {
  description = "Copy the Real-time Data Ingest Endpoint value from My Profile > Organizations."
  type        = string
}
variable "AWS_REGION" {
  description = "AWS Region"
  type        = string
}

variable "enable_server_side_encryption" {
  description = "Enable server-side encryption (SSE) at rest on the Kinesis Data Firehose delivery stream."
  type        = bool
  default     = false
}

variable "firehose_encryption_key_arn" {
  description = "Optional ARN of an existing customer-managed KMS key to use for delivery stream encryption. Leave blank to use an AWS-owned key or to create a new key (see create_encryption_key). Only applies when enable_server_side_encryption is true."
  type        = string
  default     = ""
}

variable "create_encryption_key" {
  description = "Create a new customer-managed KMS key for delivery stream encryption. Only applies when enable_server_side_encryption is true and firehose_encryption_key_arn is left blank."
  type        = bool
  default     = false
}