variable "security_group_name" {
    type = string
    description = "(optional) describe your variable"
    default = "demo-sg"
}

variable "ingress_port" {
    type = string
    description = "(optional) describe your variable"
#    default = "22"
}

variable "key_pair_name" {
    type = string
    description = "(optional) describe your variable"
    default = "demo-key-pair"
}

variable "instance_type" {
    type = string
    description = "(optional) describe your variable"
    default = "t3.micro"
}

variable "root_block_device_volume_type" {
    type = string
    description = "(optional) describe your variable"
    default = "gp2" 
}

variable "root_block_device_volume_size" {
    type = string
    description = "(optional) describe your variable"
    default = 10
}