provider "aws" {
  region = "ap-south-1" 
}

#creating role
resource "aws_iam_role" "my-cluster-role" {
  name = "my-eks-role" 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
} 

resource "aws_iam_role" "my-node-role" {
  name = "node-role" 
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
} 

#attaching policy to role 
resource "aws_iam_role_policy_attachment" "cluster-policy-attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.my-cluster-role.name
} 

resource "aws_iam_role_policy_attachment" "node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.my-node-role.name
}

resource "aws_iam_role_policy_attachment" "node-policy1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.my-node-role.name
}

resource "aws_iam_role_policy_attachment" "node-policy2" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role = aws_iam_role.my-node-role.name
}

#createing vpc
resource "aws_vpc" "my-eks-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "terraform-eks-vpc"
  }
} 

#creating internet gatway
resource "aws_internet_gateway" "tf-eks-igw" {
  vpc_id = aws_vpc.my-eks-vpc.id
}

#creating subnets
resource "aws_subnet" "private-sub-1"{
    vpc_id = aws_vpc.my-eks-vpc.id
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.0.0/19"
    tags = {
      "Name" = "private-subnet-1"
    }
}

resource "aws_subnet" "private-sub-2"{
    vpc_id = aws_vpc.my-eks-vpc.id
    availability_zone = "ap-south-1b"
    cidr_block = "10.0.32.0/19"
    tags = {
      Name = "private-sub-2"
    }
}

resource "aws_subnet" "public-sub-1"{
    vpc_id = aws_vpc.my-eks-vpc.id
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
    cidr_block = "10.0.64.0/19"
    tags = {
      Name = "public-sub"
    }
}

#creating route table
resource "aws_route" "eks-private-rt" {
  route_table_id = aws_vpc.my-eks-vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.tf-eks-igw.id
}

resource "aws_route" "eks-public-rt" {
  route_table_id = aws_vpc.my-eks-vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.tf-eks-igw.id
}

#subnet association in RT
resource "aws_route_table_association" "private-rt-as1" {
  subnet_id = aws_subnet.private-sub-1.id
  route_table_id = aws_route.eks-private-rt.id
}

resource "aws_route_table_association" "private-rt-as2" {
  subnet_id = aws_subnet.private-sub-2.id
  route_table_id = aws_route.eks-private-rt.id
}

resource "aws_route_table_association" "public-rt-as1" {
  subnet_id = aws_subnet.public-sub-1.id
  route_table_id = aws_route.eks-public-rt.id
}

#creating NAT Gtw
resource "aws_eip" "nat-gtw" {
  vpc = true
  tags = {
    Name = "tf-nat-gtw"
  }
}

resource "aws_nat_gateway" "eks-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public-1c.id
  tags = {
    Name = "eks-nat"
  }
  depends_on = [ aws_internet_gateway.eks-igw ]
}
