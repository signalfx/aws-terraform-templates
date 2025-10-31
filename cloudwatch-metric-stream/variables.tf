variable splunk_access_token {
  description = "Copy your Splunk Observability access token with INGEST authorization scope from Settings > Access Tokens."
  type = string
}

variable splunk_ingest_url {
  description = "Copy the Real-time Data Ingest Endpoint value from My Profile > Organizations."
  type = string
}
variable "AWS_REGION" {
  description = "AWS Region"
  type        = string
}