using ComplianceService.Data;

namespace ComplianceService.Models;

public class KycInitiateRequest
{
    public string UserId    { get; set; } = "";
    public string ReturnUrl { get; set; } = "";
}

public class KycInitiateResult
{
    public string  UserId          { get; set; } = "";
    public string  StripeSessionId { get; set; } = "";
    public string? ClientSecret    { get; set; }
    public string? VerificationUrl { get; set; }
}

public class KycStatusResult
{
    public string    UserId          { get; set; } = "";
    public KycStatus Status          { get; set; }
    public string?   RejectionReason { get; set; }
    public DateTime? LastUpdated     { get; set; }
}
