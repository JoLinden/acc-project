variable "key_pair" {
  description = "Key pair name"
  type        = string
  sensitive   = true
  default     = ""
}

variable "clients" {
  description = "Number of clients to launch"
  type        = number
  sensitive   = false
  default     = 2
}