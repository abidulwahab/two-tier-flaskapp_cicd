terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "5.4.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "kubeadm_demo_vpc" {

  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    # NOTE: very important to use an uppercase N to set the name in the console
    Name = "kubeadm_demo_vpc"
    "kubernetes.io/cluster/kubernetes" = "owned"
  }
  
}

resource "aws_subnet" "kubeadm_demo_subnet" {

  vpc_id = aws_vpc.kubeadm_demo_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = { 
    Name = "kubadm_demo_public_subnet"
  }
  
}

resource "aws_internet_gateway" "kubeadm_demo_igw" {
  vpc_id = aws_vpc.kubeadm_demo_vpc.id

  tags = { 
    Name = "Kubeadm Demo Internet GW"
  }

}

resource "aws_route_table" "kubeadm_demo_routetable" {
  vpc_id = aws_vpc.kubeadm_demo_vpc.id

  route { 
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubeadm_demo_igw.id
  }

  tags = {
    Name = "kubeadm Demo IGW route table"
  }

}

resource "aws_route_table_association" "kubeadm_demo_route_association" {
  subnet_id = aws_subnet.kubeadm_demo_subnet.id
  route_table_id = aws_route_table.kubeadm_demo_routetable.id
}

resource "aws_security_group" "kubeadm_demo_sg_flannel" {
  name = "flannel-overlay-backend"
  tags = {
    Name = "Flannel Overlay backend"
  }

  ingress {
    description = "flannel overlay backend"
    protocol = "udp"
    from_port = 8285
    to_port = 8285
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "flannel vxlan backend"
    protocol = "udp"
    from_port = 8472
    to_port =  8472
    cidr_blocks = ["0.0.0.0/0"]
  }
  
}

resource "aws_security_group" "kubadm_demo_sg_common" {
  name = "common-ports"
  tags = { 
    Name = "common ports"
  }
  
  ingress {
    description = "Allow SSH"
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    protocol = "tcp"
    from_port = 80
    to_port = 80 
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    protocol = "tcp"
    from_port = 8080
    to_port = 8080 
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}
resource "aws_security_group" "kubeadm_demo_sg_control_plane" {
  name = "kubeadm-control-plane security group"
  ingress {
    description = "API Server"
    protocol = "tcp"
    from_port = 6443
    to_port = 6443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubelet API"
    protocol = "tcp"
    from_port = 2379
    to_port = 2380
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd server client API"
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kube Scheduler"
    protocol = "tcp"
    from_port = 10259
    to_port = 10259
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kube Contoller Manager"
    protocol = "tcp"
    from_port = 10257
    to_port = 10257
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "Control Plane SG"
  }
}


resource "aws_security_group" "kubeadm_demo_sg_worker_nodes" {
  name = "kubeadm-worker-node security group"

  ingress {
    description = "kubelet API"
    protocol = "tcp"
    from_port = 10250
    to_port = 10250
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodePort services"
    protocol = "tcp"
    from_port = 30000
    to_port = 32767
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = "Worker Nodes SG"
  }
  
}

resource "tls_private_key" "kubadm_demo_private_key" {
  
  algorithm = "RSA"
  rsa_bits  = 4096

  provisioner "local-exec" { # Create a "pubkey.pem" to your computer!!
    command = "echo '${self.public_key_pem}' > ./pubkey.pem"
  }
}

resource "aws_key_pair" "kubeadm_demo_key_pair" {
  key_name = var.keypair_name
  public_key = tls_private_key.kubadm_demo_private_key.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.kubadm_demo_private_key.private_key_pem}' > ./private-key.pem"
  }
  
}

resource "aws_instance" "kubeadm_demo_control_plane" {
  ami = var.ubuntu_ami
  instance_type = "t2.medium"
  key_name = aws_key_pair.kubeadm_demo_key_pair.key_name
  associate_public_ip_address = true
  security_groups = [
    aws_security_group.kubadm_demo_sg_common.name,
    aws_security_group.kubeadm_demo_sg_flannel.name,
    aws_security_group.kubeadm_demo_sg_control_plane.name,
  ]
user_data = <<-EOF
#!/bin/bash
### Ansible installation
sudo apt update
sudo apt install ansible -y
ansible --version
ansible-galaxy collection install cloud.terraform

### Jenkins installation
sudo apt update -y
sudo apt install openjdk-11-jdk -y
sudo apt install wget -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update -y
sudo apt install jenkins -y
sudo usermod -aG docker jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

### Docker installation
sudo apt update -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker
EOF


  root_block_device {
    volume_type = "gp2"
    volume_size = 14
  }

  tags = {
    Name = "Kubeadm Master"
    Role = "Control plane node"
  }

  provisioner "local-exec" {
    command = "echo '' > ./files/hosts; echo 'master ${self.public_ip}' >> ./files/hosts"
  }
}

resource "aws_instance" "kubeadm_demo_worker_nodes" {
  count = var.worker_nodes_count
  ami = var.ubuntu_ami
  instance_type = "t2.micro"
  key_name = aws_key_pair.kubeadm_demo_key_pair.key_name
  associate_public_ip_address = true
  security_groups = [
    aws_security_group.kubeadm_demo_sg_flannel.name,
    aws_security_group.kubadm_demo_sg_common.name,
    aws_security_group.kubeadm_demo_sg_worker_nodes.name,
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags = {
    Name = "Kubeadm Worker ${count.index}"
    Role = "Worker node"
  }

  provisioner "local-exec" {
    command = "echo 'worker-${count.index} ${self.public_ip}' >> ./files/hosts"
  }
  
}

resource "ansible_host" "kubadm_demo_control_plane_host" {
  depends_on = [
    aws_instance.kubeadm_demo_control_plane
  ]
  name = "control_plane"
  groups = ["master"]
  variables = {
    ansible_user = "ubuntu"
    ansible_host = aws_instance.kubeadm_demo_control_plane.public_ip
    ansible_ssh_private_key_file = "./private-key.pem"
    node_hostname = "master"
  }
}

resource "ansible_host" "kubadm_demo_worker_nodes_host" {
  depends_on = [
    aws_instance.kubeadm_demo_worker_nodes
  ]
  count = 2
  name = "worker-${count.index}"
  groups = ["workers"]
  variables = {
    node_hostname = "worker-${count.index}"
    ansible_user = "ubuntu"
    ansible_host = aws_instance.kubeadm_demo_worker_nodes[count.index].public_ip
    ansible_ssh_private_key_file = "./private-key.pem"
  }
}
