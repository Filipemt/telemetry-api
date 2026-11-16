package motadev.telemetryapi.service;


import lombok.RequiredArgsConstructor;
import motadev.telemetryapi.dto.TelemetryPayload;
import motadev.telemetryapi.entity.Telemetry;
import motadev.telemetryapi.repository.TelemetryRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.health.application.ReadinessStateHealthIndicator;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TelemetryService {
    private static final Logger log = LoggerFactory.getLogger(TelemetryService.class);
    private final TelemetryRepository telemetryRepository;
    private final ReadinessStateHealthIndicator readinessStateHealthIndicator;

    @Transactional
    public void processTelemetry(TelemetryPayload payload) {
        log.debug("Processing incoming telemetry payload for hostname: {}", payload.hostname());

        Telemetry telemetry = Telemetry.builder()
                .hostname(payload.hostname())
                .cpuUsagePercentage(payload.cpuUsagePercentage())
                .memoryTotalMb(payload.memoryTotalMb())
                .memoryUsedMb(payload.memoryUsedMb())
                .diskTotalGb(payload.diskTotalGb())
                .diskUsedGb(payload.diskUsedGb())
                .systemUptimeSeconds(payload.systemUptimeSeconds())
                .build();

        telemetryRepository.save(telemetry);
        log.info("Telemetry data succesfully persisted for hostname: {}", payload.hostname());
    }

    @Transactional(readOnly = true)
    public List<Telemetry> getLatestTelemetry() {
        log.debug("Fetching latest telemetry data from the database");
        return telemetryRepository.findTop100ByOrderByCapturedAtDesc();
    }
}
