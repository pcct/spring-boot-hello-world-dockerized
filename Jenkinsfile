node {
    def gitRepository = "https://github.com/pcct/spring-boot-hello-world-dockerized.git"
	def containerName = "spring-boot-hello-world-dockerized"
    def dockerImageTag = "${containerName}-r.${env.BUILD_NUMBER}"
    def registry = "pcctavares/devops"
    def registryCredential = 'dockerhub'

	def mvnHome = tool 'maven'
	def dockerImage

    environment {
        registry = "pcctavares/devops"
        registryCredential = 'dockerhub'
        dockerImage = ''
    }

	stage('Build') {
	    echo "Cloning the git repository ${gitRepository}"
	    git "${gitRepository}"

	    echo "Build project"
	    sh "'${mvnHome}/bin/mvn' clean package"

	    echo "Creating the docker image ${dockerImageTag}"
	    dockerImage = docker.build("${dockerImageTag}")
	}

	stage('Inspection'){
        echo "Starting docker image ${dockerImageTag}"
        sh "docker run --name spring-boot-hello-world-dockerized -d -p 2222:2222 ${dockerImageTag}"
	}

	stage('Decision'){
	    echo "Decision"
	    sh "docker stop ${containerName}"
        sh "docker rm ${containerName}"
	}

	stage('Registry'){
        echo "Registry"
        docker.withRegistry('https://hub.docker.com/', registryCredential) {
           dockerImage.push("${env.BUILD_NUMBER}")
             dockerImage.push("latest")
         }
    }

    stage('Report'){
        echo "Report"
    }

}