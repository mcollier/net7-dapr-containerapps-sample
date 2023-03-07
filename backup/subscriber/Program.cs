using System.Text.Json.Serialization;
using Dapr;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

// Dapr will send serialized event object vs. being raw CloudEvent
app.UseCloudEvents();

// Needed for Dapr pub/sub routing.
app.MapSubscribeHandler();

app.MapGet("/", () => "Hello World!");

app.MapPost("/orders", [Topic("orders-pubsub", "orders")] (Order order) =>
{
    app.Logger.LogInformation("{now}: Received event for order {orderId}.", DateTime.Now, order.OrderId);
    return Results.Ok();
});

app.Run();


public record Order(
    [property: JsonPropertyName("orderId")] int OrderId,
    [property: JsonPropertyName("total")] double TotalAmount,
    [property: JsonPropertyName("count")] int ItemCount
);