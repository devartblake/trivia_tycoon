using ComplianceService.Data;

namespace ComplianceService.Models;

public class ConsentRequest
{
    public string UserId      { get; set; } = "";
    public string ConsentType { get; set; } = "";
    public bool   Granted     { get; set; }
}

public class DataSubjectRequestResult
{
    public Guid              RequestId   { get; set; }
    public string            UserId      { get; set; } = "";
    public DataRequestType   RequestType { get; set; }
    public DataRequestStatus Status      { get; set; }
    public string            Message     { get; set; } = "";
    public DateTime          CreatedAt   { get; set; }
}
