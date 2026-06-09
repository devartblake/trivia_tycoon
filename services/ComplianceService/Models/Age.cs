using ComplianceService.Data;

namespace ComplianceService.Models;

public class AgeVerificationRequest
{
    public string  UserId      { get; set; } = "";
    public DateOnly DateOfBirth { get; set; }
}

public class AgeVerificationResult
{
    public string    UserId         { get; set; } = "";
    public AgeStatus AgeStatus      { get; set; }
    public bool      IsCoppaCompliant { get; set; }
    public bool      IsPrizeEligible  { get; set; }
    public int       MinAgeRequired   { get; set; }
}
