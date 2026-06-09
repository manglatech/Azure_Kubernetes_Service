package com.demo.aks.client;

import com.demo.aks.model.User;
import com.demo.aks.model.UserRequest;
import com.demo.aks.model.UsersResponse;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

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

    public User createUser(UserRequest request) {
        return userServiceRestClient.post()
                .uri("/api/users")
                .body(request)
                .retrieve()
                .onStatus(HttpStatusCode::isError, (req, res) -> {
                    throw new ResponseStatusException(res.getStatusCode(), "User service error on create");
                })
                .body(User.class);
    }

    public User updateUser(Long id, UserRequest request) {
        return userServiceRestClient.put()
                .uri("/api/users/{id}", id)
                .body(request)
                .retrieve()
                .onStatus(HttpStatusCode::isError, (req, res) -> {
                    throw new ResponseStatusException(res.getStatusCode(), "User service error on update");
                })
                .body(User.class);
    }
}
