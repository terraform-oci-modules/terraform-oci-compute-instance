variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string
}


variable "ssh_public_key" {
  description = "SSH public key string to inject into the instance"
  type        = string
  default     = null
}
