# Spring Cloud: Eureka + Gateway + Config + Microservice
This is just an example how to build, configure and run bunch of few Spring Cloud features together.

## Eureka
Eureka is a standard Spring Cloud discovery service. The service is designed to store information
about running String microservices and provide this information on request.
In short, each microservice publishes an entry about itself at startup and deletes it at the end.
Each entry contains at least Id and IP.
The service can be used by other microservices, but more often through the API Gateway.

Spring does not provide runnable module with Eureka, but it is very easy to create using `@EnableEurekaServer` annotation:
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {
	public static void main(String[] args) {
		SpringApplication.run(EurekaServerApplication.class, args);
	}
}
```

Additionally, this code requires the following configuration:
```yml
server:
    port: 8761

spring:
    application:
        name: eureka-server

eureka:
    client:
        fetch-registry: false
        register-with-eureka: false
        service-url:
            defaultZone: http://localhost:8081/eureka
```
The `eureka.client.*` properties are set to `false` because we don't want to publish Eureka in itself.

Spring Cloud Eureka requires only one dependency (excluding test dependencies):
```xml
	<dependencies>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
		</dependency>
	</dependencies>
```

At a minimum, this is all you need to do to get the Eureka service up and running.

## Gateway
The next component of this example is the API Gateway.
Spring Cloud contains a reactive implementation of the Gateway API, for this you need to include related dependencies in your project:
```xml
	<dependencies>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-gateway</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
		</dependency>
	</dependencies>
```

The implementation of the API Gateway is also very simple and does not even differ at all from an ordinary Spring Boot application:
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ApiGatewayApplication {
	public static void main(String[] args) {
		SpringApplication.run(ApiGatewayApplication.class, args);
	}
}
```
But the configuration is a bit more complicated
```yml
server:
    port: 8080

spring:
    application:
        name: api-gateway
    cloud:
        gateway:
            discovery:
                locator:
                    enabled: true
                    lower-case-service-id: true
            routes:
            -   id: greeting
                predicates:
                - Path=/greeting
                uri: lb://greeting-ms

eureka:
    client:
        service-url:
            defaultZone: http://localhost:8761/eureka
```
* `spring.cloud.gateway.discovery.locator` must be `enabled` and `lower-case-service-id` is set to `true` to use micro service Ids in lower case.
* `spring.cloud.gateway.routes` contains an array of routes which gateway will process. In our case only one route is described for path `/greeting`.
This path is used in our microservice (see below). The route config provides possibility to have access to microservive without microservice Id in URL.
So instead of `/greeting-ms/greeting` we can just use `/greeting` and the gateway will forward the request to the appropriate microservice.
* `eureka.client.service-url.defaultZone` defines URL of Eureka service.

## Configuration server
The configuration server is used to configure other Spring Boot applications from a single point. Of course, in this project, this may seem unnecessary,
because there is only one microservice. But just for an example.
To use Configuration server just add the next dependency:
```xml
	<dependencies>
	    <dependency>
	        <groupId>org.springframework.cloud</groupId>
	        <artifactId>spring-cloud-config-server</artifactId>
	    </dependency>
	</dependencies>

```
As usually, an implementation is very easy:
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.SecurityAutoConfiguration;
import org.springframework.cloud.config.server.EnableConfigServer;

@SpringBootApplication
@EnableConfigServer
public class ConfigServer {
    public static void main(String[] args) {
        SpringApplication.run(ConfigServer.class, args);
    }
}

```
All you need to configure:
```yaml
server:
    port: 8888

spring:
    cloud:
        config.server.native.search-locations: classpath:/config

```
And add `greeting-ms.properties` file into `/config` directory inside class path:
```properties
dev.example.greeting=Hello world!
```

## Microservice
And finally the microservice. The microservice contains one controller which process reuqest with path `/greeting` (see gateway config above).
You need to add `@EnableDiscoveryClient` annotation to your app:
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class GreetingApplication {

	public static void main(String[] args) {
		SpringApplication.run(GreetingApplication.class, args);
	}

}
```
```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GreetingController {

	@Value("${dev.example.greeting}")
	private String greeting;

	@GetMapping("/greeting")
	public String greeting() {
		return this.greeting;
	}
	
}
```

And configuration:
```yml
server:
    port: 0

spring:
    application:
        name: greeting-ms
    config:
        import: optional:configserver:http://localhost:8888
eureka:
    client:
        service-url:
            defaultZone: http://localhost:8761/eureka
    instance:
        instance-id: ${spring.application.name}:${random.value}
```

Also you need to add the following dependencies:
```xml
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.cloud</groupId>
			<artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
		</dependency>
	</dependencies>

```

That's all. As you can see, the implementation is very simple, all the difficulties, as always, are hidden in the nuances,
primarily in the Eureka and Gateway configurations. Also be aware that using a config server with config files inside is not a good idea for real world applications.
