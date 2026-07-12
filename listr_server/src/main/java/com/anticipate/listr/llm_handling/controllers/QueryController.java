package com.anticipate.listr.llm_handling.controllers;

//import com.anticipate.listr.llm_handling.entities.Query;
import com.anticipate.listr.jwt_handling.entities.User;
import com.anticipate.listr.jwt_handling.services.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.util.StreamUtils;
import java.util.List;

@RequestMapping("/queries")
@RestController
public class QueryController {

    @Value("classpath:request_openers/n1.txt")
    private Resource n1Resource;

    private final UserService userService;

    public QueryController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/n1") // NinjaOne
    public String handleQuery() throws IOException {
        String openerText = StreamUtils.copyToString(
                n1Resource.getInputStream(), StandardCharsets.UTF_8);

        return openerText;
    }
}