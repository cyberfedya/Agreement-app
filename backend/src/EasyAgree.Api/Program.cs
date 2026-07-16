using EasyAgree.Api.Endpoints;
using EasyAgree.Application;
using EasyAgree.Infrastructure;
using EasyAgree.Infrastructure.Persistence.Seed;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddApplication();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<EasyAgree.Api.GlobalExceptionHandler>();

builder.Services.AddCors(options =>
{
    // Demo-only: the Flutter client runs from an arbitrary local origin/port.
    // Tighten this to an allow-list before this goes anywhere near production.
    options.AddDefaultPolicy(policy => policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
});

var app = builder.Build();

// Any unhandled exception from a use case (LLM/vision provider outage, DB
// error, etc.) is logged with full context here and turned into a
// consistent ProblemDetails JSON body instead of a raw ASP.NET error page -
// the client's ApiClient already treats any non-2xx as a generic server
// error, but without this, the failure left zero diagnostic trail server-side.
app.UseExceptionHandler();

// Configure the HTTP request pipeline.
// Demo-only, same as the open CORS policy above: exposed regardless of
// environment so the API is browsable at /scalar without a separate deploy
// flag. Gate this behind IsDevelopment() (or an explicit config switch)
// before this goes anywhere near real production.
app.MapOpenApi();
app.MapScalarApiReference();

// No UseHttpsRedirection(): this container never serves HTTPS directly
// (Kestrel listens on plain HTTP only, per docker-compose) - TLS is
// terminated upstream by ngrok/nginx. With it enabled, the middleware
// could never determine an HTTPS port to redirect to and logged a warning
// on every single request.
app.UseCors();

// Apply migrations and seed agreement templates before accepting requests.
// The app never reads agreement JSON files at runtime — only PostgreSQL.
using (var startupScope = app.Services.CreateScope())
{
    var seedService = startupScope.ServiceProvider.GetRequiredService<AgreementSeedService>();
    await seedService.RunAsync();
}

app.MapTemplateEndpoints();
app.MapDealEndpoints();
app.MapProfileEndpoints();
app.MapDocumentEndpoints();

app.Run();
