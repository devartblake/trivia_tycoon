using ComplianceService.Data;
using ComplianceService.Models;
using ComplianceService.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// ── Database ─────────────────────────────────────────────────────────────────
builder.Services.AddDbContext<ComplianceDbContext>(options =>
    options.UseSqlite(
        builder.Configuration.GetConnectionString("ComplianceDb") ?? "Data Source=compliance.db"));

// ── Configuration ─────────────────────────────────────────────────────────────
builder.Services.Configure<ComplianceOptions>(builder.Configuration.GetSection("Compliance"));
builder.Services.Configure<StripeOptions>(builder.Configuration.GetSection("Stripe"));

// ── Services ──────────────────────────────────────────────────────────────────
builder.Services.AddScoped<IAuditLogService,                  AuditLogService>();
builder.Services.AddScoped<IKycService,                       KycService>();
builder.Services.AddScoped<IAgeVerificationService,           AgeVerificationService>();
builder.Services.AddScoped<IGeoComplianceService,             GeoComplianceService>();
builder.Services.AddScoped<IAmlService,                       AmlService>();
builder.Services.AddScoped<IDataPrivacyService,               DataPrivacyService>();
builder.Services.AddScoped<IComplianceOrchestrationService,   ComplianceOrchestrationService>();

// ── ASP.NET ───────────────────────────────────────────────────────────────────
builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(
        new System.Text.Json.Serialization.JsonStringEnumConverter()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title   = "Compliance Service",
        Version = "v1",
        Description = "US regulatory compliance: KYC (Stripe Identity), COPPA age-gating, " +
                      "CCPA data-subject rights, FinCEN/BSA AML screening, state-level geo-blocking.",
    }));

builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.WithOrigins(
            builder.Configuration.GetSection("AllowedOrigins").Get<string[]>()
                ?? ["http://localhost:3000", "http://localhost:5000"])
        .AllowAnyHeader()
        .AllowAnyMethod()));

var app = builder.Build();

// ── DB migration ──────────────────────────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ComplianceDbContext>();
    db.Database.EnsureCreated();
}

// ── Middleware ────────────────────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseAuthorization();
app.MapControllers();

app.Run();
