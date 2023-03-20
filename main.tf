locals {
  cidr_block             = "10.0.0.0/16"
  cidr_block_list        = split(",", local.cidr_block)
  security_group_id_list = split(",", module.security_group.security_group_ids)
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = local.cidr_block

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


module "security_group" {
  source      = "clouddrove/security-group/aws"
  version     = "1.3.0"
  name        = "security-group"
  environment = "test"
  protocol    = "tcp"
  label_order = ["name", "environment"]
  vpc_id      = module.vpc.default_vpc_id
  allowed_ip  = ["0.0.0.0/0"]
  #   allowed_ipv6  = ["2405:201:5e00:3684:cd17:9397:5734:a167/128"]
  allowed_ports = [22, 80, 8080, 443]
}

output "my_output" {
  value = split(",", module.security_group.security_group_ids)
}
# output "subnet_outputs" {
#   value = module.vpc.private_subnets[0]
# }





resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "s3_policy" {
  name        = "s3_policy"
  description = "Full access to S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

# resource "aws_iam_policy" "eks_policy" {
#   name        = "eks_policy"
#   description = "Full access to EKS"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = "eks:*"
#         Resource = "*"
#       }
#     ]
#   })
# }

resource "aws_iam_policy_attachment" "s3_attachment" {
  name       = "s3_attachment"
  policy_arn = aws_iam_policy.s3_policy.arn
  roles      = [aws_iam_role.ec2_role.name]
}

# resource "aws_iam_policy_attachment" "eks_attachment" {
#   name       = "eks_attachment"
#   policy_arn = aws_iam_policy.eks_policy.arn
#   roles      = [aws_iam_role.ec2_role.name]
# }







# # Ubuntu image selected 
# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   #   owners = ["099720109477"] # Canonical
# }





resource "aws_instance" "web" {
  ami                         = "ami-005f9685cb30f234b" 
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  availability_zone           = "us-east-1a"
  vpc_security_group_ids      = local.security_group_id_list
  key_name                    = "deployer-key" 
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  tags = {
    Name = "Jenkins"
  }
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ec2-user"
      #   private_key = aws_key_pair.my_key_pair.key_name
      #   private_key = "${file("~/Downloads/terraform-jenkins.cer")}"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
    inline = [
      "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo amazon-linux-extras install epel -y",
      "sudo yum install daemonize -y",
      "sudo yum install jenkins -y",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo yum install git -y",
      "curl -L https://git.io/get_helm.sh | bash -s -- --version v3.8.2",
      "sudo yum install -y yum-utils",
      "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo",
      "sudo yum -y install terraform",
      "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.23.13/2022-10-31/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin",
      # "sudo mkdir -p /var/lib/jenkins/bin && sudo cp ./kubectl /var/lib/jenkins/bin/kubectl && export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/var/lib/jenkins/bin",
    ]
  }

}