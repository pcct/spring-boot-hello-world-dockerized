node {
    def gitRepository = "https://github.com/pcct/spring-boot-hello-world-dockerized.git"
    def imageName = "spring-boot-hello-world-dockerized"
    def registry = "pcctavares/spring-boot-hello-world-dockerized"
    def registryCredential = 'dockerhub'

	def mvnHome = tool 'maven'
	def dockerImage


	stage('Build') {
	    echo "Cloning the git repository ${gitRepository}"
	    git "${gitRepository}"

	    echo "Build project"
	    sh "'${mvnHome}/bin/mvn' clean package"

	    echo "Creating the docker image ${imageName}"
	    dockerImage = docker.build("${imageName}")
	}

	stage('Inspection'){
        echo "Starting docker image ${imageName}"
        sh "docker run --name spring-boot-hello-world-dockerized -d -p 2222:2222 ${imageName}"
	}

	stage('Decision'){
	    echo "Decision"
	    sh "docker stop ${imageName}"
        sh "docker rm ${imageName}"
	}

	stage('Registry'){
        echo "Registry"
        docker.withRegistry('', "${registryCredential}") {
           dockerImage.push("${env.BUILD_NUMBER}")
             dockerImage.push("latest")
         }
    }

    stage('Report'){
        echo "Report"
    }

}