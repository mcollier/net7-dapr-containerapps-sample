using System.Text.Json.Serialization;
using Dapr;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

// Dapr will send serialized event object vs. being raw CloudEvent
app.UseCloudEvents();

// Needed for Dapr pub/sub routing.
app.MapSubscribeHandler();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapGet("/", () => "Hello World!");

// Declarative syntax not support in Azure Container Apps :(
// TODO: Pull topic from configuration.
// app.MapPost("/evh-orders", [Topic("eventhubs-pubsub", "evh-orders")] (Order order) =>
app.MapPost("/orders", [Topic("eventhubs-pubsub", "evh-orders")] (Order order) =>
{
    Console.WriteLine(order);
    Console.WriteLine($"{DateTime.Now}:Received event {order.OrderId}.");
    return Results.Ok();
});


// app.MapPost("/orders", [Topic("eventhubs-pubsub", "evh-orders")] (Order order) =>
// {
//     Console.WriteLine($"{DateTime.Now}:Received event {order.OrderId}.");
//     return Results.Ok();
// });


await app.RunAsync();


public record Order([property: JsonPropertyName("orderId")] int OrderId);