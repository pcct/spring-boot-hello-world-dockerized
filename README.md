# Spring Boot Hello World Dockerized
__Hello World RESTful web service application using [Spring Boot](https://spring.io/projects/spring-boot) deployed in [Docker](https://www.docker.com/)__

## Prerequisites
* [Git](https://git-scm.com/)
* [OpenJdk](https://openjdk.java.net/)
* [Maven](https://maven.apache.org/)
* [Docker/Docker-Compose](https://www.docker.com/)

## Steps

#### Clone source code from git:
```
git clone https://github.com/pcct/spring-boot-hello-world-dockerized .
```
#### Build an executable JAR:
```
mvn clean package
```
#### Build Docker image:
```
docker build -t="hello-world" .
```
#### Run with docker-compose:
```
docker-compose up -d 
```
#### Test application with curl command:
```
curl localhost:8083
```
> The respone should be:  
> Hello World

#### Stop Docker Container:
```
docker-compose down
```

