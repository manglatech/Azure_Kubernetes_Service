package com.demo.aks.web;

import com.demo.aks.client.UserServiceClient;
import com.demo.aks.model.User;
import com.demo.aks.model.UserRequest;
import com.demo.aks.model.UsersResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class DemoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserServiceClient userServiceClient;

    @Test
    void helloReturnsMessage() throws Exception {
        mockMvc.perform(get("/api/hello"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    void demoUsersReturnsUsersFromUserService() throws Exception {
        when(userServiceClient.fetchUsers()).thenReturn(new UsersResponse(
                2,
                List.of(
                        new User(1L, "Alice Johnson", "alice.johnson@example.com"),
                        new User(2L, "Bob Smith", "bob.smith@example.com")
                )
        ));

        mockMvc.perform(get("/api/demo/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.source").value("azure-user-service"))
                .andExpect(jsonPath("$.count").value(2))
                .andExpect(jsonPath("$.users[0].name").value("Alice Johnson"));
    }

    @Test
    void createUserProxiesToUserService() throws Exception {
        when(userServiceClient.createUser(any(UserRequest.class)))
                .thenReturn(new User(6L, "Frank Castle", "frank.castle@example.com"));

        mockMvc.perform(post("/api/demo/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Frank Castle\",\"email\":\"frank.castle@example.com\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(6))
                .andExpect(jsonPath("$.name").value("Frank Castle"))
                .andExpect(jsonPath("$.email").value("frank.castle@example.com"));
    }

    @Test
    void updateUserProxiesToUserService() throws Exception {
        when(userServiceClient.updateUser(eq(1L), any(UserRequest.class)))
                .thenReturn(new User(1L, "Alice Updated", "alice.updated@example.com"));

        mockMvc.perform(put("/api/demo/users/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Alice Updated\",\"email\":\"alice.updated@example.com\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("Alice Updated"))
                .andExpect(jsonPath("$.email").value("alice.updated@example.com"));
    }

    @Test
    void healthIsUp() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
