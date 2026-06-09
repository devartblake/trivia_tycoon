using ComplianceService.Data;

namespace ComplianceService.Models;

public class TransactionCheckRequest
{
    public string  UserId          { get; set; } = "";
    public decimal Amount          { get; set; }
    public string  Network         { get; set; } = "";
    public string  TransactionType { get; set; } = "";
}

public class AmlCheckResult
{
    public string    UserId         { get; set; } = "";
    public AmlStatus AmlStatus      { get; set; }
    public bool      IsAllowed      { get; set; }
    public bool      RequiresReview { get; set; }
    public string?   AlertReason    { get; set; }
    public decimal   DailyTotal     { get; set; }
}
