variable splunk_access_token {
  description = "Copy your Splunk Observability access token with INGEST authorization scope from Settings > Access Tokens."
  type = string
}

variable splunk_ingest_url {
  description = "Find the real-time data ingest URL in Profile > Account Settings > Endpoints. Note: do NOT include endpoint path here: for instance use https://ingest.us1.signalfx.com instead of https://ingest.us1.signalfx.com/v1/cloudwatch_metric_stream."
  type = string
}
variable "AWS_REGION" {
  description = "AWS Region"
  type        = string
}