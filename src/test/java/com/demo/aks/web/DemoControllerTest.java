package com.demo.aks.web;

import com.demo.aks.client.UserServiceClient;
import com.demo.aks.model.User;
import com.demo.aks.model.UsersResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
    void healthIsUp() throws Exception {
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }
}
