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
                        ansible-galaxy collection install cloud.terraform:2.12
                        ansible-playbook -i inventory.yml playbook.yml --private-key $SSH_KEY -u ubuntu
                    '''
                }
            }
        }
        stage("Build & Test"){
            steps{
                sh "docker build . -t flaskapp"
            }
        }
        stage("Push to DockerHub") {
            steps {
                withCredentials([usernamePassword(credentialsId: "dockerhubCred", 
                                                  usernameVariable: 'DOCKER_HUB_USER', 
                                                  passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
                    // Log in to Docker Hub using the provided credentials
                    sh "echo \$DOCKER_HUB_PASSWORD | docker login -u \$DOCKER_HUB_USER --password-stdin"
                    // Tag the Docker image
                    sh "docker tag flaskapp \$DOCKER_HUB_USER/flaskapp:latest"
                    // Push the Docker image to Docker Hub
                    sh "docker push \$DOCKER_HUB_USER/flaskapp:latest" 
                }
            }
        }
    }
}

