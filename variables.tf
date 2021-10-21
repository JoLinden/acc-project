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

variable "instance_suffix" {
  description = "Suffix to add to instance names"
  type        = string
  default     = ""
}