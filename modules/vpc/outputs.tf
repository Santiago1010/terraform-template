output "vpc_id" {
  description = "The ID of the VPC. Required by almost every other AWS resource (security groups, subnets, load balancers, etc.)."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC. Useful for writing security group rules that allow all intra-VPC traffic."
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "List of IDs for all public subnets, one per AZ. Use for internet-facing resources like Kong or a load balancer."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks for all public subnets. Useful for security group ingress rules scoped to the public tier."
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "List of IDs for all private subnets, one per AZ. Use for internal resources like databases, caches, and Vault."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks for all private subnets. Useful for security group rules scoped to the private tier."
  value       = aws_subnet.private[*].cidr_block
}

output "public_route_table_id" {
  description = "The ID of the public route table. Useful if additional routes need to be added externally (e.g., VPC peering)."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs, one per AZ. When a NAT Gateway is added, routes will be injected into these tables."
  value       = aws_route_table.private[*].id
}
