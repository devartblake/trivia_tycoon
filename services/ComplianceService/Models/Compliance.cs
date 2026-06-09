using ComplianceService.Data;

namespace ComplianceService.Models;

public class ComplianceStatus
{
    public string UserId          { get; set; } = "";
    public KycStatus     KycStatus     { get; set; }
    public AgeStatus     AgeStatus     { get; set; }
    public GeoStatus     GeoStatus     { get; set; }
    public AmlStatus     AmlStatus     { get; set; }
    public ConsentStatus ConsentStatus { get; set; }
    public string? LastStateCode  { get; set; }
    public bool CanUseCrypto      { get; set; }
    public bool CanReceivePrizes  { get; set; }
    public bool CanCollectData    { get; set; }
    public List<string> RequiredActions { get; set; } = [];
    public DateTime? LastUpdated  { get; set; }
}

public class ComplianceOptions
{
    public int MinAgeForPrizes  { get; set; } = 18;
    public int MinAgeForCoppa   { get; set; } = 13;
    public decimal AmlDailyThresholdUsd             { get; set; } = 10_000m;
    public decimal AmlSingleTransactionThresholdUsd { get; set; } = 3_000m;

    // States where real-money prize games face significant legal restrictions.
    // Consult legal counsel before adjusting this list for your jurisdiction.
    public HashSet<string> RestrictedStates { get; set; } =
    [
        "AZ", "AR", "CT", "DE", "IL", "IN", "IA",
        "LA", "MD", "MT", "SC", "SD", "TN", "VT",
    ];
}

public class StripeOptions
{
    public string SecretKey      { get; set; } = "";
    public string WebhookSecret  { get; set; } = "";
    public string PublishableKey { get; set; } = "";
}
