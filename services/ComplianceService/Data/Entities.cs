using System.ComponentModel.DataAnnotations;

namespace ComplianceService.Data;

public enum KycStatus    { NotStarted, Pending, Approved, Rejected, Expired }
public enum AgeStatus    { Unknown, CoppaMinor, Minor, Adult }
public enum GeoStatus    { Unchecked, Allowed, Restricted, Blocked }
public enum AmlStatus    { Clear, UnderReview, Flagged, Blocked }
public enum ConsentStatus { NotGiven, Partial, Full }
public enum DataRequestType   { Export, Deletion, Correction, OptOut }
public enum DataRequestStatus { Pending, Processing, Completed, Rejected }

public class ComplianceRecord
{
    [Key] public string UserId { get; set; } = "";
    public KycStatus     KycStatus     { get; set; } = KycStatus.NotStarted;
    public AgeStatus     AgeStatus     { get; set; } = AgeStatus.Unknown;
    public GeoStatus     GeoStatus     { get; set; } = GeoStatus.Unchecked;
    public AmlStatus     AmlStatus     { get; set; } = AmlStatus.Clear;
    public ConsentStatus ConsentStatus { get; set; } = ConsentStatus.NotGiven;
    public string? LastStateCode { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class KycRecord
{
    [Key] public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId { get; set; } = "";
    public string? StripeSessionId  { get; set; }
    public string? StripeSessionUrl { get; set; }
    public KycStatus Status { get; set; } = KycStatus.NotStarted;
    public string? RejectionReason  { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class AgeRecord
{
    [Key] public string UserId { get; set; } = "";
    // SHA-256 of "YYYY-MM-DD" — never store DOB in plaintext
    public string? DateOfBirthHash      { get; set; }
    public int?    AgeAtVerification    { get; set; }
    public AgeStatus Status             { get; set; } = AgeStatus.Unknown;
    public DateTime VerifiedAt          { get; set; } = DateTime.UtcNow;
}

public class AmlRecord
{
    [Key] public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId          { get; set; } = "";
    public decimal Amount         { get; set; }
    public string Network         { get; set; } = "";
    public string TransactionType { get; set; } = "";
    public AmlStatus Status       { get; set; } = AmlStatus.Clear;
    public string? AlertReason    { get; set; }
    public DateTime CreatedAt     { get; set; } = DateTime.UtcNow;
}

public class AuditLogEntry
{
    [Key] public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId    { get; set; } = "";
    public string EventType { get; set; } = "";
    public string Details   { get; set; } = "";
    public string Outcome   { get; set; } = "";
    public string? IpAddress { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ConsentRecord
{
    [Key] public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId      { get; set; } = "";
    // e.g. "data_collection", "marketing", "coppa_parental"
    public string ConsentType { get; set; } = "";
    public bool   Granted     { get; set; }
    public string? IpAddress  { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class DataSubjectRequest
{
    [Key] public Guid Id { get; set; } = Guid.NewGuid();
    public string UserId                 { get; set; } = "";
    public DataRequestType   RequestType { get; set; }
    public DataRequestStatus Status      { get; set; } = DataRequestStatus.Pending;
    public string? Notes                 { get; set; }
    public string? ExportDownloadUrl     { get; set; }
    public DateTime  CreatedAt           { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt         { get; set; }
}
