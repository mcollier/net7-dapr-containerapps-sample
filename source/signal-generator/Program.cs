using Azure.Messaging.EventHubs.Producer;

// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");

int maxSignals = 100;

var connectionString = "";
var eventHubName = "";

await using (var producer = new EventHubProducerClient(connectionString, eventHubName))
{
    using EventDataBatch eventBatch = await producer.CreateBatchAsync();

    for (int i = 0; i < maxSignals; i++)
    {
        Console.WriteLine($"Sending signal {i} at {DateTime.Now}.");
    }
}