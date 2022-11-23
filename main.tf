provider "oci" {}
/*
resource "oci_bastion_bastion" "bastion" {
	bastion_type = "standard"
	compartment_id = data.oci_identity_compartment.free_compartment.id
	target_subnet_id = oci_core_subnet.private_subnet.id
	name = "bastion"
	client_cidr_block_allow_list = ["0.0.0.0/0"]
	depends_on = [oci_core_instance.amd_instance[0]]
}

resource "oci_bastion_session" "bastion_session" {
	bastion_id = oci_bastion_bastion.bastion.id
	key_details {
		public_key_content =  var.ssh_public_key
	}
	target_resource_details {
		session_type = "MANAGED_SSH"
		target_resource_id = oci_core_instance.amd_instance[0].id
		target_resource_operating_system_user_name = "ubuntu"
	}
	display_name = "Bastion"
	key_type = "PUB"
	depends_on = [oci_core_instance.amd_instance[0]]
}
*/

/*
resource "oci_core_nat_gateway" "nat_gateway" {
	compartment_id = data.oci_identity_compartment.free_compartment.id
	vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}
*/

resource "oci_core_public_ip" "arm_public_ip" {
	compartment_id = data.oci_identity_compartment.free_compartment.id
	lifetime = "RESERVED"
	display_name = "arm"
	private_ip_id = data.oci_core_private_ips.arm_private_ips.private_ips[0]["id"]
}

data "oci_core_private_ips" "arm_private_ips" {
	ip_address = oci_core_instance.arm_instance.private_ip
	subnet_id = oci_core_subnet.generated_oci_core_subnet.id
}

resource "oci_core_instance" "arm_instance" {
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Bastion"
        }
        plugins_config {
            desired_state = "ENABLED"
            name = "Block Volume Management"
        }
	}
    availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = "cLVZ:UK-LONDON-1-AD-3"
	compartment_id = data.oci_identity_compartment.free_compartment.id
	create_vnic_details {
		assign_private_dns_record = "true"
		assign_public_ip = "false"
		subnet_id = oci_core_subnet.generated_oci_core_subnet.id
        nsg_ids = [oci_core_network_security_group.arm_security_group.id]
	}
	display_name = "ulysses"
	instance_options {
		are_legacy_imds_endpoints_disabled = "true"
	}
	is_pv_encryption_in_transit_enabled = "true"
	metadata = {
		"ssh_authorized_keys" = var.ssh_public_key
	}
	shape = "VM.Standard.A1.Flex"
	shape_config {
		memory_in_gbs = "24"
		ocpus = "4"
	}
	source_details {
		source_id = "ocid1.image.oc1.uk-london-1.aaaaaaaa2mhbjjj4s5uraazyqly6wovardusdh5qnr4cdgpczqyh5slze2gq"
		source_type = "image"
    }
    defined_tags = {
      "${oci_identity_tag_namespace.permissions_tag_namespace.name}.${oci_identity_tag.permissions_role_tag.name}": "Artifactory",
    }
}

/*
resource "oci_core_instance" "amd_instance" {
	count = 2
	agent_config {
		is_management_disabled = "false"
		is_monitoring_disabled = "false"
		plugins_config {
			desired_state = "ENABLED"
			name = "Vulnerability Scanning"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Compute Instance Monitoring"
		}
		plugins_config {
			desired_state = "ENABLED"
			name = "Bastion"
		}
	}
	availability_config {
		recovery_action = "RESTORE_INSTANCE"
	}
	availability_domain = "cLVZ:UK-LONDON-1-AD-2"
	compartment_id = data.oci_identity_compartment.free_compartment.id
	create_vnic_details {
		assign_private_dns_record = "true"
		assign_public_ip = "false"
		subnet_id = oci_core_subnet.private_subnet.id
	}
	display_name = "amd-${count.index}"
	instance_options {
		are_legacy_imds_endpoints_disabled = "true"
	}
	is_pv_encryption_in_transit_enabled = "true"
	metadata = {
		"ssh_authorized_keys" = var.ssh_public_key
	}
	shape = "VM.Standard.E2.1.Micro"
	source_details {
		source_id = "ocid1.image.oc1.uk-london-1.aaaaaaaazh5x3j7e7cfhwipts6jsvkkbb7cmxp7c6dmace22x26uydytskjq"
		source_type = "image"
	}
}
*/

resource "oci_core_vcn" "generated_oci_core_vcn" {
	cidr_block = "10.0.0.0/16"
	compartment_id = data.oci_identity_compartment.free_compartment.id
	display_name = "free"
    dns_label = "vcn08011405"
    is_ipv6enabled = true
}

resource "oci_core_subnet" "generated_oci_core_subnet" {
	cidr_block = "10.0.0.0/24"
	compartment_id = data.oci_identity_compartment.free_compartment.id
	display_name = "public"
	dns_label = "subnet08011405"
	route_table_id = oci_core_vcn.generated_oci_core_vcn.default_route_table_id
    vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}

resource "oci_core_subnet" "private_subnet" {
	cidr_block = "10.0.1.0/24"
	compartment_id = data.oci_identity_compartment.free_compartment.id
	display_name = "private"
	dns_label = "subnet08011406"
	route_table_id = oci_core_route_table.private_route_table.id
	vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}

resource "oci_core_internet_gateway" "generated_oci_core_internet_gateway" {
	compartment_id = data.oci_identity_compartment.free_compartment.id
	display_name = "Internet Gateway free"
	enabled = "true"
	vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}

resource "oci_core_default_route_table" "generated_oci_core_default_route_table" {
	route_rules {
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = oci_core_internet_gateway.generated_oci_core_internet_gateway.id
	}
    route_rules {
        destination = "::/0"
        destination_type = "CIDR_BLOCK"
        network_entity_id = oci_core_internet_gateway.generated_oci_core_internet_gateway.id
    }
    manage_default_resource_id = oci_core_vcn.generated_oci_core_vcn.default_route_table_id
}

resource "oci_core_route_table" "private_route_table" {
	compartment_id = data.oci_identity_compartment.free_compartment.id
	vcn_id = oci_core_vcn.generated_oci_core_vcn.id
	display_name = "private"
}

resource "oci_core_network_security_group" "arm_security_group" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  display_name = "ARM instance security group"
  vcn_id = oci_core_vcn.generated_oci_core_vcn.id
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_ssh_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "SSH inbound"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_ssh_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "SSH inbound"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_http_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "HTTP inbound"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_http_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "HTTP inbound"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_https_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "HTTPS inbound"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_https_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "HTTPS inbound"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_openvpn_tcp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "OpenVPN TCP inbound"
  tcp_options {
    destination_port_range {
      min = 1194
      max = 1195
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_openvpn_tcp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "6"
  description = "OpenVPN TCP inbound"
  tcp_options {
    destination_port_range {
      min = 1194
      max = 1195
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_sntp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "SNTP inbound"
  udp_options {
    source_port_range {
      min = 123
      max = 123
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_sntp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "SNTP inbound"
  udp_options {
    source_port_range {
      min = 123
      max = 123
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_openvpn_udp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "OpenVPN UDP inbound"
  udp_options {
    destination_port_range {
      min = 1194
      max = 1195
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_openvpn_udp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "OpenVPN UDP inbound"
  udp_options {
    destination_port_range {
      min = 1194
      max = 1195
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_dns_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "DNS inbound"
  udp_options {
    source_port_range {
      min = 53
      max = 53
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_dns_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "DNS inbound"
  udp_options {
    source_port_range {
      min = 53
      max = 53
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_dhcp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "DHCP inbound"
  udp_options {
    source_port_range {
      min = 67
      max = 68
    }
  }
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_dhcp_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "17"
  description = "DHCP inbound"
  udp_options {
    source_port_range {
      min = 67
      max = 68
    }
  }
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_icmpv4_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "1"
  description = "ICMPv4 inbound"
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_icmpv6_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "58"
  description = "ICMPv6 inbound"
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_gre_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "47"
  description = "GRE inbound"
  source = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_gre_inbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "INGRESS"
  protocol = "47"
  description = "GRE inbound"
  source = "::/0"
  source_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_ssh_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "SSH outbound"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_ssh_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "SSH outbound"
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_http_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "HTTP outbound"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_http_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "HTTP outbound"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_proxy_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "HTTP proxy outbound"
  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_proxy_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "HTTP proxy outbound"
  tcp_options {
    destination_port_range {
      min = 8080
      max = 8080
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_https_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "HTTPS outbound"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_https_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "HTTPS outbound"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_smtp_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "SMTP outbound"
  tcp_options {
    destination_port_range {
      min = 587
      max = 587
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_smtp_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "SMTP outbound"
  tcp_options {
    destination_port_range {
      min = 587
      max = 587
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_oracle_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "Oracle outbound"
  tcp_options {
    destination_port_range {
      min = 1521
      max = 1522
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_oracle_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "6"
  description = "Oracle outbound"
  tcp_options {
    destination_port_range {
      min = 1521
      max = 1522
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_sntp_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "SNTP outbound"
  udp_options {
    destination_port_range {
      min = 123
      max = 123
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_sntp_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "SNTP outbound"
  udp_options {
    destination_port_range {
      min = 123
      max = 123
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_dns_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "DNS outbound"
  udp_options {
    destination_port_range {
      min = 53
      max = 53
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_dns_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "DNS outbound"
  udp_options {
    destination_port_range {
      min = 53
      max = 53
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_dhcp_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "DHCP outbound"
  udp_options {
    destination_port_range {
      min = 67
      max = 68
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_dhcp_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "DHCP outbound"
  udp_options {
    destination_port_range {
      min = 67
      max = 68
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_openvpn_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "OpenVPN UDP outbound"
  udp_options {
    source_port_range {
      min = 1194
      max = 1195
    }
  }
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_openvpn_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "17"
  description = "OpenVPN UDP outbound"
  udp_options {
    source_port_range {
      min = 1194
      max = 1195
    }
  }
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_icmpv4_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "1"
  description = "ICMPv4 outbound"
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_icmpv6_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "58"
  description = "ICMPv6 outbound"
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv4_gre_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "47"
  description = "GRE outbound"
  destination = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "arm_ipv6_gre_outbound_security_rule" {

  network_security_group_id = oci_core_network_security_group.arm_security_group.id
  direction = "EGRESS"
  protocol = "47"
  description = "GRE outbound"
  destination = "::/0"
  destination_type = "CIDR_BLOCK"
}

resource "oci_kms_vault" "secret_vault" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  display_name = "Secret vault"
  vault_type = "DEFAULT"
}

resource "oci_kms_key" "artifactory_database_key" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  display_name = "Artifactory database key"
  key_shape {
    algorithm = "AES"
    length = 32
  }
  management_endpoint = oci_kms_vault.secret_vault.management_endpoint
  protection_mode = "SOFTWARE"
}

resource "oci_vault_secret" "artifactory_database_admin_password_encoded" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  secret_content {
    name = "artifactory_database_admin_password_encoded"
    content_type = "BASE64"
    content = base64encode(var.artifactory_database_admin_password)
  }
  secret_name = "artifactory_database_admin_password_encoded"
  vault_id = oci_kms_vault.secret_vault.id
  key_id = oci_kms_key.artifactory_database_key.id
}

resource "oci_vault_secret" "artifactory_database_artifactory_password" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  secret_content {
    name = "artifactory_database_artifactory_password"
    content_type = "BASE64"
    content = base64encode(var.artifactory_database_artifactory_password)
  }
  secret_name = "artifactory_database_artifactory_password"
  vault_id = oci_kms_vault.secret_vault.id
  key_id = oci_kms_key.artifactory_database_key.id
}

resource "oci_vault_secret" "artifactory_master_key" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  secret_content {
    name = "artifactory_master_key"
    content_type = "BASE64"
    content = base64encode(var.artifactory_master_key)
  }
  secret_name = "artifactory_master_key"
  vault_id = oci_kms_vault.secret_vault.id
  key_id = oci_kms_key.artifactory_database_key.id
}

resource "oci_vault_secret" "artifactory_join_key" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  secret_content {
    name = "artifactory_join_key"
    content_type = "BASE64"
    content = base64encode(var.artifactory_join_key)
  }
  secret_name = "artifactory_join_key"
  vault_id = oci_kms_vault.secret_vault.id
  key_id = oci_kms_key.artifactory_database_key.id
}

resource "oci_database_autonomous_database" "artifactory_database" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  db_name = "artifactory"
  admin_password = var.artifactory_database_admin_password
  autonomous_maintenance_schedule_type = "REGULAR"
  customer_contacts {
    email = "goprivacy@hotmail.com"
  }
  db_workload = "OLTP"
  display_name = "Artifactory database"
  is_free_tier = true
  whitelisted_ips = [
    oci_core_public_ip.arm_public_ip.ip_address,
    oci_core_vcn.generated_oci_core_vcn.id
  ]
  is_mtls_connection_required = true
}

resource "oci_identity_tag_namespace" "permissions_tag_namespace" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  description = "Tag namespace used for permissions handling"
  name = "Permissions"
}

resource "oci_identity_tag" "permissions_role_tag" {
  description = "Role for which the resource is used"
  name = "Role"
  tag_namespace_id = oci_identity_tag_namespace.permissions_tag_namespace.id
  validator {
    validator_type = "ENUM"
    values = ["Artifactory"]
  }
}

data "oci_objectstorage_namespace" "blob_namespace" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
}

resource "oci_objectstorage_bucket" "secret_bucket" {
  compartment_id = data.oci_identity_compartment.free_compartment.id
  name = "goprivacy-infra"
  namespace = data.oci_objectstorage_namespace.blob_namespace.namespace
  access_type = "NoPublicAccess"
  kms_key_id = oci_kms_key.artifactory_database_key.id
  depends_on = [oci_identity_policy.arm_policy]
} 

resource "oci_identity_dynamic_group" "instance_dynamic_group" {
  compartment_id = data.oci_identity_compartment.goprivacy_compartment.id
  description = "Dynamic group for ARM instance"
  matching_rule = "tag.${oci_identity_tag_namespace.permissions_tag_namespace.name}.${oci_identity_tag.permissions_role_tag.name}.value='Artifactory'"
  name = "ARMInstanceGroup"
}

resource "oci_identity_policy" "arm_policy" {
  compartment_id = data.oci_identity_compartment.goprivacy_compartment.id
  description = "Policy for ARM instance"
  name = "ARMInstancePolicy"
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.instance_dynamic_group.name} to read buckets in compartment ${data.oci_identity_compartment.free_compartment.name}",
    "allow dynamic-group ${oci_identity_dynamic_group.instance_dynamic_group.name} to read objects in compartment ${data.oci_identity_compartment.free_compartment.name} where target.bucket.name='goprivacy-infra'",
    "allow dynamic-group ${oci_identity_dynamic_group.instance_dynamic_group.name} to read vaults in compartment ${data.oci_identity_compartment.free_compartment.name} where target.vault.id='${oci_kms_vault.secret_vault.id}'",
    "allow dynamic-group ${oci_identity_dynamic_group.instance_dynamic_group.name} to use keys in compartment ${data.oci_identity_compartment.free_compartment.name} where target.key.id='${oci_kms_key.artifactory_database_key.id}'",
    "allow dynamic-group ${oci_identity_dynamic_group.instance_dynamic_group.name} to read secret-family in compartment ${data.oci_identity_compartment.free_compartment.name} where any {target.secret.id='${oci_vault_secret.artifactory_database_artifactory_password.id}',target.secret.id='${oci_vault_secret.artifactory_master_key.id}',target.secret.id='${oci_vault_secret.artifactory_join_key.id}'}",
    "allow service objectstorage-uk-london-1 to use keys in compartment ${data.oci_identity_compartment.free_compartment.name}", # where target.key.id='${oci_kms_key.artifactory_database_key.id}'",
  ]
}

data "oci_identity_compartment" "free_compartment" {
  id = "ocid1.compartment.oc1..aaaaaaaao3cgast7fjghx76urjk74gdfsworvxtzbfwcljppg6fhkamhe4xa"
}

data "oci_identity_compartment" "goprivacy_compartment" {
  id = "ocid1.tenancy.oc1..aaaaaaaare5pstrynsrzsw7k3yj546hx524dyz3ln4w5fbzlr5eepnskx7la"
}

variable "artifactory_database_admin_password" {
  type = string
}

variable "artifactory_database_artifactory_password" {
  type = string
}

variable "artifactory_master_key" {
  type = string
}

variable "artifactory_join_key" {
  type = string
}

variable "ssh_public_key" {
  type = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAuTnAc70k5CMYonsmQMZxeEnmFNyu3aMOZCe1dTh3hGKultKctKLuYgV7oiSM4QCPVVg4jDFeVxNDTMZdNsH25U2YpdMwAm4DmwKOz0TQmjPkHgD6R1HeDXCSY7MeueEdLg4f2YqzsGOC6TeOUEO30DkIkJLcppuTH/VnqwSAjmU= rsa-key-20051015"
}

