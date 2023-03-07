using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using System.Text.Json.Serialization;

using IHost host = Host.CreateApplicationBuilder().Build();

IConfiguration config = host.Services.GetRequiredService<IConfiguration>();

// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");

int maxSignals = 100;

// The Event Hub connection string is set as a user secert. Use the Event Hub namespace.
// dotnet user-secrets set "EventHub:ConnectionString" "EVENT-HUB-CONNECTION-STRING"
var connectionString = config.GetValue<string>("EventHub:ConnectionString");
Console.WriteLine(connectionString);

var eventHubName = "sensors";
var rand = new Random();

string[] sensors = {
    "d9d82237-d90c-4867-8c51-92524432bb4b",
    "c036d1be-da33-4bd6-9376-75108075288f",
    "12029d71-29bb-4aa8-a0a3-5dc30df601bf",
    "b2c0fd74-4071-4b5e-8a9f-c7e47e5cfd66"
};

await using (var producer = new EventHubProducerClient(connectionString, eventHubName))
{
    using EventDataBatch eventBatch = await producer.CreateBatchAsync();

    for (int i = 0; i < maxSignals; i++)
    {
        eventBatch.TryAdd(new EventData(new BinaryData(new SensorData(
            sensors[rand.Next(0, 4)],
            rand.NextDouble() * 85,
            DateTime.UtcNow.ToString()))));
    }

    Console.WriteLine($"Sending {maxSignals} at {DateTime.Now}.");
    await producer.SendAsync(eventBatch);
}

public record SensorData(
        [property: JsonPropertyName("sensorId")] string SensorId,
        [property: JsonPropertyName("temperature")] double Temperature,
        [property: JsonPropertyName("time")] string Datetime
        );