import boto3
import json

def get_instances():
    # Initialize the EC2 client
    ec2 = boto3.client('ec2', region_name='eu-west-2')

    # Describe instances with filters for running state and name tag
    instances = ec2.describe_instances(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},  # Filter for running instances
            {'Name': 'tag:Name', 'Values': ['Kubeadm Worker*']}      # Filter for instances with name like "Kubeadm Worker*"
        ]
    )

    # Initialize the inventory structure
    inventory = {
        "all": {
            "hosts": {},
            "vars": {
                "ansible_user": "ubuntu"  # Set the SSH user
                # "ansible_ssh_private_key_file": "~/.ssh/id_rsa"  # Uncomment if using a private key
            }
        }
    }

    # Iterate through the instances and add them to the inventory
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            public_ip = instance.get('PublicIpAddress')
            if public_ip:
                inventory["all"]["hosts"][public_ip] = {}

    return inventory

if __name__ == "__main__":
    inventory = get_instances()
    print(json.dumps(inventory, indent=2))
