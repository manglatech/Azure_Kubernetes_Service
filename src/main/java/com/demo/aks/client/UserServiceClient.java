package com.demo.aks.client;

import com.demo.aks.model.UsersResponse;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class UserServiceClient {

    private final RestClient userServiceRestClient;

    public UserServiceClient(RestClient userServiceRestClient) {
        this.userServiceRestClient = userServiceRestClient;
    }

    public UsersResponse fetchUsers() {
        return userServiceRestClient.get()
                .uri("/api/users")
                .retrieve()
                .body(UsersResponse.class);
    }
}
