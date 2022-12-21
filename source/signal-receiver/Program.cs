using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapGet("/", () => "Hello World!");

app.MapPost("/events", (SensorData sensor) =>
{
    app.Logger.LogInformation("Received event for sensor {sensorId} with temp of {temperature} degrees at {time}.", sensor.SensorId, sensor.Temperature, sensor.Datetime);
    return Results.Accepted();
});

app.Run();


public record SensorData(
        [property: JsonPropertyName("sensorId")] string SensorId,
        [property: JsonPropertyName("temperature")] double Temperature,
        [property: JsonPropertyName("time")] string Datetime
        );