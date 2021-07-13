node {
    def gitRepository = "https://github.com/pcct/spring-boot-hello-world-dockerized.git"
    def imageName = "pcctavares/spring-boot-hello-world-dockerized"
    def containerName = "spring-boot-hello-world-dockerized"
    def registryCredential = 'dockerhub'

	def mvnHome = tool 'maven'
	def dockerImage

    def inspectionResult


	stage('Build') {
	    echo "Cloning the git repository ${gitRepository}"
	    git "${gitRepository}"

	    echo "Build project"
	    sh "'${mvnHome}/bin/mvn' clean package"

	    echo "Creating the docker image ${imageName}"
	    dockerImage = docker.build("${imageName}")
	}

	stage('Inspection') {
        echo "Starting docker image ${imageName}"
        sh "docker run --name ${containerName} -d -p 2222:2222 ${imageName}"
        sh "chmod +x -R ${env.WORKSPACE}"
        script {
           inspectionResult = sh (
                script: "./inspection.sh > report.txt",
                returnStatus: true
            )
            echo "Inspection result: ${inspectionResult}"
        }
        sh "docker stop ${containerName}"
        sh "docker rm ${containerName}"
	}

	stage('Report') {
         script {
            def report = readFile(file: 'report.txt')
            println(report)
        }
    }

	stage('Decision') {
	    if(inspectionResult!=0) {
	         currentBuild.result = 'ABORTED'
	         echo "Some inspections have failed"
	         return
	    }
	}

	stage('Registry') {
	    if(inspectionResult!=0) {
            docker.withRegistry('', "${registryCredential}") {
                dockerImage.push()
            }
        }
    }

}