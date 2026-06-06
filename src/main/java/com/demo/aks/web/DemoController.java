package com.demo.aks.web;

import com.demo.aks.client.UserServiceClient;
import com.demo.aks.model.UsersResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class DemoController {

    private final UserServiceClient userServiceClient;

    @Value("${app.message:Hello from Spring Boot on AKS}")
    private String message;

    public DemoController(UserServiceClient userServiceClient) {
        this.userServiceClient = userServiceClient;
    }

    @GetMapping("/hello")
    public Map<String, Object> hello() {
        return Map.of(
                "message", message,
                "timestamp", Instant.now().toString(),
                "hostname", System.getenv().getOrDefault("HOSTNAME", "local")
        );
    }

    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of(
                "app", "aks-spring-demo",
                "stack", "Java 21 + Spring Boot 3",
                "platform", "Azure Kubernetes Service"
        );
    }

    @GetMapping("/demo/users")
    public Map<String, Object> demoUsers() {
        UsersResponse usersResponse = userServiceClient.fetchUsers();
        return Map.of(
                "source", "azure-user-service",
                "count", usersResponse.count(),
                "users", usersResponse.users(),
                "timestamp", Instant.now().toString(),
                "hostname", System.getenv().getOrDefault("HOSTNAME", "local")
        );
    }
}
