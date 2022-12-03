using Collier.Sample;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();

var app = builder.Build();

app.MapSubscribeHandler();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapGet("/", () => "Hello World!");

app.MapPost("/events", (Person person) =>
{
    app.Logger.LogInformation("My peeps, {firstname}!", person.FirstName);
    return Results.Accepted();
});


// Declarative syntax not support in Azure Container Apps :(
// TODO: Pull topic from configuration.
// app.MapPost("/person", [Topic("eventhubs-pubsub", "evh-hvscur5mtnsxq")] (Person person) =>
// {
//     Console.WriteLine($"Received event {person.FirstName}.");
//     return Results.Ok();
// });


app.Run();