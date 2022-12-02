namespace Collier.Sample;

using System.Text.Json.Serialization;

public record Person(
  [property: JsonPropertyName("firstname")] string FirstName,
  [property: JsonPropertyName("lastname")] string LastName,
  [property: JsonPropertyName("age")] int Age
);