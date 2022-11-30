using Collier.Sample;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapGet("/", () => "Hello World!");

app.MapPost("/events", (DaprData<Order> requestData) =>
{
    return Results.Accepted();
});

app.MapPost("/person", (Person requestData) =>
{
    // return Results.Accepted();
    return Results.Ok(requestData.FirstName);
});

app.Run();