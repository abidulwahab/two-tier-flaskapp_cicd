pipeline {
    agent any
    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False' // Disable SSH key checking for Ansible
    }    
    stages{
        stage("Code"){
            steps{
                git url: "https://github.com/abidulwahab/two-tier-flaskapp_cicd.git", branch: "main"
            }
        }
        stage('Run Ansible Playbook') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                    sh '''
                        export ANSIBLE_HOST_KEY_CHECKING=False
                        ansible-playbook -i inventory.yml playbook.yml --private-key $SSH_KEY -u ubuntu
                    '''
                }
            }
        }
    }
}

