using System.Text.Json.Serialization;
using Dapr.Client;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

string topicName = "evh-orders";
string pubSubName = "eventhubs-pubsub";

Random rand = new Random();

app.MapPost("/scheduled", async () =>
{
    app.Logger.LogInformation("Timer time!");
    using (var daprClient = new DaprClientBuilder().Build())
    {
        int orderId = rand.Next(1, 100);
        app.Logger.LogInformation($"${DateTime.Now} Publishing order {orderId} now.");
        await daprClient.PublishEventAsync(pubSubName, topicName, new Order(orderId));
    }
});

await app.RunAsync();

public record Order([property: JsonPropertyName("orderId")] int OrderId);