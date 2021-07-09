node {
    environment {
        repository = 'spring-boot-hello-world-dockerized'
        registry = 'pcctavares/' + repository
        registryCredential = 'dockerhub'
        dockerImage = ''

        gitRepository = "https://github.com/pcct/spring-boot-hello-world-dockerized.git"
    }

    def mvnHome = tool 'maven'

	stage('Build') {
	    echo "Cloning the git repository $gitRepository"
	    git gitRepository

	    echo "Build project"
	    sh "'${mvnHome}/bin/mvn' clean package"

	    echo "Building docker image"
	    dockerImage = docker.build registry + ":$BUILD_NUMBER"
	}

	stage('Inspection'){
        echo "Starting docker image $registry"
        sh "docker run --name $repository -d -p 2222:2222 $registry"
	}

	stage('Decision'){
	    echo "Decision"
	    sh "docker stop $repository"
        sh "docker rm $repository"
	}

	stage('Registry'){
        echo "Registry"
        docker.withRegistry('', registryCredential) {
           dockerImage.push()
         }
         sh "docker rmi $registry:$BUILD_NUMBER"
    }

    stage('Report'){
        echo "Report"
    }

}