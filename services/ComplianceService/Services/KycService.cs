using ComplianceService.Data;
using ComplianceService.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Stripe;
using Stripe.Identity;

namespace ComplianceService.Services;

public interface IKycService
{
    Task<KycInitiateResult> InitiateVerificationAsync(string userId, string returnUrl);
    Task<KycStatusResult>   GetStatusAsync(string userId);
    Task HandleStripeWebhookAsync(string jsonPayload, string signatureHeader);
}

public class KycService(
    ComplianceDbContext db,
    IAuditLogService audit,
    IOptions<StripeOptions> stripeOpts) : IKycService
{
    private readonly StripeOptions _stripe = stripeOpts.Value;

    public async Task<KycInitiateResult> InitiateVerificationAsync(string userId, string returnUrl)
    {
        StripeConfiguration.ApiKey = _stripe.SecretKey;

        var session = await new VerificationSessionService().CreateAsync(new VerificationSessionCreateOptions
        {
            Type      = "document",
            Metadata  = new Dictionary<string, string> { ["userId"] = userId },
            ReturnUrl = returnUrl,
        });

        db.KycRecords.Add(new KycRecord
        {
            UserId           = userId,
            StripeSessionId  = session.Id,
            StripeSessionUrl = session.Url,
            Status           = KycStatus.Pending,
            CreatedAt        = DateTime.UtcNow,
            UpdatedAt        = DateTime.UtcNow,
        });

        await UpsertKycStatusAsync(userId, KycStatus.Pending);
        await db.SaveChangesAsync();
        await audit.LogAsync(userId, "kyc_initiated", $"sessionId={session.Id}", "pending");

        return new KycInitiateResult
        {
            UserId          = userId,
            StripeSessionId = session.Id,
            ClientSecret    = session.ClientSecret,
            VerificationUrl = session.Url,
        };
    }

    public async Task<KycStatusResult> GetStatusAsync(string userId)
    {
        var cr     = await db.ComplianceRecords.FindAsync(userId);
        var latest = await db.KycRecords
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.UpdatedAt)
            .FirstOrDefaultAsync();

        return new KycStatusResult
        {
            UserId          = userId,
            Status          = cr?.KycStatus ?? KycStatus.NotStarted,
            RejectionReason = latest?.RejectionReason,
            LastUpdated     = latest?.UpdatedAt,
        };
    }

    public async Task HandleStripeWebhookAsync(string jsonPayload, string signatureHeader)
    {
        StripeConfiguration.ApiKey = _stripe.SecretKey;

        Event stripeEvent;
        try
        {
            stripeEvent = EventUtility.ConstructEvent(jsonPayload, signatureHeader, _stripe.WebhookSecret);
        }
        catch (StripeException)
        {
            throw new InvalidOperationException("Stripe webhook signature verification failed.");
        }

        if (stripeEvent.Data.Object is not VerificationSession session) return;

        if (!session.Metadata.TryGetValue("userId", out var userId)) return;

        var record = await db.KycRecords
            .Where(r => r.StripeSessionId == session.Id)
            .FirstOrDefaultAsync();

        if (record is null) return;

        var newStatus = session.Status switch
        {
            "verified"       => KycStatus.Approved,
            "requires_input" => KycStatus.Rejected,
            "canceled"       => KycStatus.Rejected,
            _                => KycStatus.Pending,
        };

        record.Status          = newStatus;
        record.RejectionReason = session.LastError?.Reason;
        record.UpdatedAt       = DateTime.UtcNow;

        await UpsertKycStatusAsync(userId, newStatus);
        await db.SaveChangesAsync();
        await audit.LogAsync(userId, "kyc_webhook", $"event={stripeEvent.Type} sessionId={session.Id}", newStatus.ToString());
    }

    private async Task UpsertKycStatusAsync(string userId, KycStatus status)
    {
        var cr = await db.ComplianceRecords.FindAsync(userId);
        if (cr is null)
        {
            cr = new ComplianceRecord { UserId = userId };
            db.ComplianceRecords.Add(cr);
        }
        cr.KycStatus  = status;
        cr.UpdatedAt  = DateTime.UtcNow;
    }
}
