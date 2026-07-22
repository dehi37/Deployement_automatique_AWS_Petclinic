package org.springframework.samples.petclinic.system;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/actuator/health")
    public ResponseEntity<String> health() {
        // Simule une erreur pour tester le rollback automatique
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("{\"status\":\"DOWN\"}");
    }

}