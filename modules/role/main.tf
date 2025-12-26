resource "aws_iam_role" "devops" {
  name                  = "${var.name}-devops"
  path                  = "/devops/ci/"
  assume_role_policy    = var.assume_role_policy
  force_detach_policies = true
}

resource "aws_iam_policy" "devops" {
  name        = "${var.name}-devops"
  path        = "/devops/ci/"
  description = "${var.name} policy for devops ci"
  policy      = var.policy
}

resource "aws_iam_role_policy_attachment" "devops" {
  role       = aws_iam_role.devops.name
  policy_arn = aws_iam_policy.devops.arn
}
