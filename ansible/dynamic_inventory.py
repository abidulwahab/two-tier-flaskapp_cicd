import boto3
import json
import os

def get_instances():
    ec2 = boto3.client('ec2', region_name='eu-west-2')
    instances = ec2.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

    inventory = {
        "all": {
            "hosts": {},
            "vars": {
                "ansible_user": "ubuntu"  #  Set the SSH user
 #               "ansible_ssh_private_key_file": "~/.ssh/id_rsa"  # ✅ Use the private key
           }
        }
    }

    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            public_ip = instance.get('PublicIpAddress')
            if public_ip:
                inventory["all"]["hosts"][public_ip] = {}

    return inventory

if __name__ == "__main__":
    inventory = get_instances()
    print(json.dumps(inventory, indent=2))
