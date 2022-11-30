namespace Collier.Sample;

using System.Text.Json.Serialization;

public record DaprData<T>(
  [property: JsonPropertyName("data")] T Data
);

public record Order(
  [property: JsonPropertyName("orderId")] int OrderId
);

public record DaprSubscription(
  [property: JsonPropertyName("pubsubname")] string PubsubName,
  [property: JsonPropertyName("topic")] string Topic,
  [property: JsonPropertyName("route")] string Route);


public record Person(
  [property: JsonPropertyName("firstname")] string FirstName,
  [property: JsonPropertyName("lastname")] string LastName,
  [property: JsonPropertyName("age")] int Age
);