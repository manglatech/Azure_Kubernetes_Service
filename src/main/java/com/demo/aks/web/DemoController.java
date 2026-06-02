package com.demo.aks.web;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class DemoController {

    @Value("${app.message:Hello from Spring Boot on AKS}")
    private String message;

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
}
