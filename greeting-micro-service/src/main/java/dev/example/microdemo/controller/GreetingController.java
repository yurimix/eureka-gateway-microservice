package dev.example.microdemo.controller;

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
