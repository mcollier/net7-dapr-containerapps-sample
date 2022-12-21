using System.Text.Json.Serialization;

namespace signal_generator
{
    public record SensorData(
        [property: JsonPropertyName("sensorId")] string SensorId,
        [property: JsonPropertyName("temperature")] double Temperature,
        [property: JsonPropertyName("time")] string Datetime
        );
}