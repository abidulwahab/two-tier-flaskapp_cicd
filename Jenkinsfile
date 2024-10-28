pipeline {
    agent any
    
    stages{
        stage("Code"){
            steps{
                git url: "https://github.com/abidulwahab/two-tier-flaskapp_cicd.git", branch: "main"
            }
        }
        stage("Build & Test"){
            steps{
                sh "docker build . -t flaskapp"
            }
        }
        stage("Push to DockerHub") {
            steps {
                withCredentials([usernamePassword(credentialsId: "dockerHub", 
                                                  usernameVariable: 'DokerHubPassword', 
                                                  passwordVariable: 'DokerHubUser')]) {
                    // Log in to Docker Hub using the provided credentials
                    sh "echo \$DokerHubPassword | docker login -u \$DokerHubUser --password-stdin"
                    // Tag the Docker image
                    sh "docker tag flaskapp \$DokerHubUser/flaskapp:latest"
                    // Push the Docker image to Docker Hub
                    sh "docker push \$DokerHubUser/flaskapp:latest" 
                }
            }
        }
        stage("Deploy"){
            steps{
                sh "docker-compose down && docker-compose up -d"
            }
        }
    }
}

