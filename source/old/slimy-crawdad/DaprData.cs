namespace Collier.Sample;

using System.Text.Json.Serialization;

public record DaprData<T>(
  [property: JsonPropertyName("data")] T Data
);
