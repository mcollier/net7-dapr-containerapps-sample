using System.Text.Json.Serialization;
using Dapr.Client;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

string topicName = app.Configuration["TopicName"];
string pubSubName = app.Configuration["PubSubName"];

Random rand = new Random();

app.MapPost("/scheduled", async () =>
{
    app.Logger.LogInformation("Timer time!");

    using (var daprClient = new DaprClientBuilder().Build())
    {
        int orderId = rand.Next(1, 100);
        double amount = rand.NextDouble() * 35;
        int items = rand.Next(2, 12);

        app.Logger.LogInformation($"{DateTime.Now} Publishing order {orderId} now.");

        await daprClient.PublishEventAsync(pubSubName, topicName, new Order(orderId, amount, items));
    }
});

await app.RunAsync();

public record Order(
    [property: JsonPropertyName("orderId")] int OrderId,
    [property: JsonPropertyName("total")] double TotalAmount,
    [property: JsonPropertyName("count")] int ItemCount
);