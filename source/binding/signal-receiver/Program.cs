using System.Text.Json.Serialization;
using Dapr;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

// Dapr - needed for pub/sub routing.
// app.MapSubscribeHandler();

app.MapGet("/", () => "Hello World!");

// Use for input binding
app.MapPost("/events", (SensorData sensor) =>
{
    app.Logger.LogInformation("Received a great event for sensor {sensorId} with temp of {temperature} degrees at {time}.", sensor.SensorId, sensor.Temperature, sensor.DateTime);
    return Results.Accepted();
});

await app.RunAsync();


public record SensorData(
        [property: JsonPropertyName("sensorId")] string SensorId,
        [property: JsonPropertyName("temperature")] double Temperature,
        [property: JsonPropertyName("time")] string DateTime
        );


#region old debugging
// use for input binding
//app.MapPost("/events", (SensorData sensor) =>

// app.MapPost("/events", [Topic("eventspubsub", "sensors", enableRawPayload: true)] async (HttpRequest request) =>
// app.MapPost("/events", [Topic("eventspubsub", "sensors", true)] () =>
// app.Logger.LogInformation(sensor.ToString());
// string body = "";
// using (StreamReader stream = new StreamReader(request.Body))
// {
//     body = await stream.ReadToEndAsync();
// }
// app.Logger.LogInformation(body);

// use for pub/sub
// NOTE: Do NOT set enableRawPayload when using Event Hub. Doing so seems to cause Dapr
// to post received event using a 'data_base64' element, which is a base64 encoded string
// of the original event data. 

// app.MapPost("/events", [Topic("eventspubsub", "sensors")] (SensorData sensor) =>
#endregion