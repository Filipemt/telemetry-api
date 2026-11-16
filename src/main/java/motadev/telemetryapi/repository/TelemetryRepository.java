package motadev.telemetryapi.repository;

import motadev.telemetryapi.entity.Telemetry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TelemetryRepository extends JpaRepository<Telemetry, Long> {
    List<Telemetry> findTop100ByOrderByCapturedAtDesc();
}
