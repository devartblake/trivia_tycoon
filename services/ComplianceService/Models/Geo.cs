using ComplianceService.Data;

namespace ComplianceService.Models;

public class GeoCheckRequest
{
    public string UserId    { get; set; } = "";
    public string StateCode { get; set; } = "";
}

public class GeoCheckResult
{
    public string    UserId            { get; set; } = "";
    public string    StateCode         { get; set; } = "";
    public GeoStatus GeoStatus         { get; set; }
    public bool      IsAllowed         { get; set; }
    public string?   RestrictionReason { get; set; }
}
