using System.Text.Json.Serialization;
using Dapr.Client;


// See https://aka.ms/new-console-template for more information
Console.WriteLine("Hello, World!");

string topicName = "evh-orders";
string pubSubName = "eventhubs-pubsub";

using (var daprClient = new DaprClientBuilder().Build())
{
    for (int i = 0; i < 10; i++)
    {
        Console.WriteLine($"Sending event {i}.");

        // Publish an event/message using Dapr PubSub
        // await daprClient.PublishEventAsync(pubSubName, topicName, new Order(i));

        // Set the metadata property 'rawPayload' to send NOT using CloudEvent.
        var metadata = new Dictionary<string, string>
        {
            { "rawPayload", "true" }
        };
        await daprClient.PublishEventAsync(pubSubName, topicName, new Order(i), metadata);
    }
}

public record Order([property: JsonPropertyName("orderId")] int OrderId);

// This is a CloudEvent
// {
//     "data": {
//         "orderId": 7
//     },
//   "datacontenttype": "application/json",
//   "id": "09d4d23e-3579-4532-ae83-1892961ba2dd",
//   "pubsubname": "eventhubs-pubsub",
//   "source": "publisher",
//   "specversion": "1.0",
//   "time": "2022-12-06T17:12:58Z",
//   "topic": "evh-orders",
//   "traceid": "00-c98ae3af434b0b977f7886f264b5a455-2609032828a0931f-01",
//   "traceparent": "00-c98ae3af434b0b977f7886f264b5a455-2609032828a0931f-01",
//   "tracestate": "",
//   "type": "com.dapr.event.sent"
// }