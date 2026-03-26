variable "env" {
  description = "Environment name (e.g., prod, dev, staging)"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "instance_tenancy" {
  description = "Tenancy option for instances launched into the VPC (default/dedicated)"
  type        = string
  default     = "default" 
}

variable "enable_dns_hostnames" {
  description = "Boolean flag to enable/disable DNS hostnames in the VPC"
  type        = bool
  default     = true 
  }

variable "enable_dns_support" {
  description = "Boolean flag to enable/disable DNS support in the VPC"
  type        = bool
  default     = true 
}

variable "public1_subnet_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
}

variable "public2_subnet_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
}

variable "private1_subnet_cidr" {
  description = "CIDR block for the first private subnet"
  type        = string
}

variable "private2_subnet_cidr" {
  description = "CIDR block for the second private subnet"
  type        = string
}

variable "zone1" {
  description = "First availability zone for resource placement"
  type        = string
}

variable "zone2" {
  description = "Second availability zone for resource placement"
  type        = string
}