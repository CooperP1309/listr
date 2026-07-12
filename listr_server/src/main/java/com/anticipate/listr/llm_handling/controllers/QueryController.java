package com.anticipate.listr.llm_handling.controllers;

//import com.anticipate.listr.llm_handling.entities.Query;
import com.anticipate.listr.jwt_handling.entities.User;
import com.anticipate.listr.jwt_handling.services.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RequestMapping("/queries")
@RestController
public class QueryController {

    private final UserService userService;

    public QueryController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/n1") // NinjaOne
    public ResponseEntity<User> authenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        User currentUser = (User) authentication.getPrincipal();

        // open file
        System.out.println("\n\nAuthenticated user: " + currentUser.getUsername() + "\n\n");

        // print contents


        return ResponseEntity.ok(currentUser);
    }

    @GetMapping("/")
    public ResponseEntity<List<User>> allUsers() {
        List <User> users = userService.allUsers();

        return ResponseEntity.ok(users);
    }
}