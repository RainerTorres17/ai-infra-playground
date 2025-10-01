output "bucket_name" {
    value = aws_s3_bucket.this.bucket
}

output "bucker_arn"{
    value = aws_s3_bucket.this.arn
}

output "artifact_policy_arn"{
    value = aws_iam_policy.artifact_policy.arn

}

output "db_endpoint"{
    value = aws_db_instance.this.endpoint
}

output "dp_port"{
    value = aws_db_instance.this.port
}

output "db_name"{
    value = aws_db_instance.this.db_name
}

output "db_sg_id" {
    value = aws_security_group.rds.id
}