using EasyAgree.Api.Endpoints;
using EasyAgree.Application;
using EasyAgree.Infrastructure;
using EasyAgree.Infrastructure.Persistence.Seed;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddApplication();

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

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
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

app.Run();
