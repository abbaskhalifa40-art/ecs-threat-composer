output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  # The [*] "splat" collects the id from every subnet copy into a list.
  value = aws_subnet.public[*].id
}
