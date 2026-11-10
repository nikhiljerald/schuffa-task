# NETWORK ACCOUNT 

# Central routing and inspected east-west and egress traffic.

resource "aws_ec2_transit_gateway" "central" {
  description                     = "Cross-account network backbone"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  auto_accept_shared_attachments  = "disable"
}

# this route table will route production traffic to approved inspection paths
resource "aws_ec2_transit_gateway_route_table" "prod_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.central.id
  tags = { Name = "prod-inspection-entry" }
}

# this route table will route DEV/TEST traffic to approved inspection paths
resource "aws_ec2_transit_gateway_route_table" "nonprod_spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.central.id
  tags = { Name = "nonprod-inspection-entry" }
}

# similary we can have a route table like 'Firewall-Return-RT' to route inspected traffic to the appropriate destination VPC
# Also we can have an 'Egress-RT'	to route the internet-bound traffic through the egress attachment



# for Network Firewall, the rule groups are generated ONLY from approved communication intents.
# In this code, I have assumed that var.approved_rule_group_arns stands for a trusted pipeline output.
resource "aws_networkfirewall_firewall_policy" "central" {
  name = "approved-communications-only"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
    stateful_default_actions = ["aws:drop_strict"]

    dynamic "stateful_rule_group_reference" {
      for_each = var.approved_rule_group_arns
      content {
        resource_arn = stateful_rule_group_reference.value
      }
    }
  }
}

# I have used the Native TGW Network Function Attachment. Therefore, there is NO separate Inspection or Firewall VPC. 
# I could have implemented the Inspection/Firewall VPC method, but it comes with the overhead of maintaining the underlying infrastructure and high availability. 
# However, if the application is supposed to be highly secure, and we do not want AWS to manage our infrastructyre, then I reccomend going for the Inspection/Firewall VPC mechanism.
resource "aws_networkfirewall_firewall" "central" {
  name                = "central-tgw-inspection"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.central.arn
  transit_gateway_id  = aws_ec2_transit_gateway.central.id
  availability_zone_mapping {
    availability_zone_id = var.az_ids[0]
  }
  availability_zone_mapping {
    availability_zone_id = var.az_ids[1]
  }
  delete_protection   = true
}

# PSEUDOCODE for next steps:
# - Share TGW with workload accounts through AWS RAM, control attachment acceptance.
# - Create/provision Workload A/B and Egress VPC TGW attachments.
# - Associate production and nonproduction attachments with their inspection-entry tables.
# - Add STATIC TGW routes to the firewall network-function attachment, then dedicated post-inspection/return routes to workload or egress attachments in BOTH directions.
# - Egress VPC: private TGW attachment subnets, public NAT GW per AZ, IGW, correct return routes.
# - Guardrail: no uninspected cross-VPC or direct-internet bypass route.
# - Stream firewall and TGW flow logs to the Logging Account.

variable "az_ids" {
  description = "Two AZ IDs in the chosen Region"
  type        = list(string)
}
variable "approved_rule_group_arns" {
  description = "Approved and published rule groups — never user-controlled input"
  type        = list(string)
  default     = []
}
