
resource "tls_private_key" "my_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key-pair"
  public_key = tls_private_key.my_key_pair.public_key_openssh
}

# resource "aws_key_pair" "terraform-jenkins" {
#   key_name   = "terraform-jenkins-key"
#   public_key = tls_private_key.my_key_pair.public_key_openssh
# }

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqiEwXtWY7bPQcmmQnuksz+cIjMQPPAvucdwM5H7cHEXMSMaYINWvv+WbdVIopmpWz1CGpOUREeU4mFiHdysTyKP3l2P+nbriq8LCQRKHzJfoJzYUPdeG7s8Oi8L89JLr1o8g+vNmiuc/NFzC6nVaiuvRPYbQ/ljS9/VzljXjS/IvIEhrBNLkfAFNhcih3FHw4VvF8AS+p/1Lr5qYYO/pQjUHrvAsKaZMCO/cvcRMABzHbXI/n4wgAzKMrJFSIHwrXfyyLSTS/XMz5TSJREMYVghDbPeBg1U1XUxCldg5v0tr+jZBQOFyxBJo7ieRsNJ1qa3vMlPTL3S2GiZxP/7uh dean@Deans-MBP"
}