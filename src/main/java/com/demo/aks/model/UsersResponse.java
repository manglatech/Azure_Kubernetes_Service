package com.demo.aks.model;

import java.util.List;

public record UsersResponse(int count, List<User> users) {
}
