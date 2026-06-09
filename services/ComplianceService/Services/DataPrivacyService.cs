using ComplianceService.Data;
using ComplianceService.Models;
using Microsoft.EntityFrameworkCore;

namespace ComplianceService.Services;

public interface IDataPrivacyService
{
    Task<DataSubjectRequestResult> RequestExportAsync(string userId);
    Task<DataSubjectRequestResult> RequestDeletionAsync(string userId);
    Task RecordConsentAsync(string userId, string consentType, bool granted, string? ipAddress = null);
    Task<IReadOnlyList<ConsentRecord>>     GetConsentsAsync(string userId);
    Task<IReadOnlyList<DataSubjectRequest>> GetRequestsAsync(string userId);
}

public class DataPrivacyService(ComplianceDbContext db, IAuditLogService audit) : IDataPrivacyService
{
    public Task<DataSubjectRequestResult> RequestExportAsync(string userId)
        => CreateRequestAsync(userId, DataRequestType.Export);

    public Task<DataSubjectRequestResult> RequestDeletionAsync(string userId)
        => CreateRequestAsync(userId, DataRequestType.Deletion);

    private async Task<DataSubjectRequestResult> CreateRequestAsync(string userId, DataRequestType type)
    {
        // Prevent duplicate open requests of the same type
        var open = await db.DataSubjectRequests
            .Where(r => r.UserId == userId && r.RequestType == type && r.Status == DataRequestStatus.Pending)
            .FirstOrDefaultAsync();

        if (open is not null)
            return Map(open, "A request of this type is already pending.");

        var request = new DataSubjectRequest
        {
            UserId      = userId,
            RequestType = type,
            Status      = DataRequestStatus.Pending,
            CreatedAt   = DateTime.UtcNow,
        };

        db.DataSubjectRequests.Add(request);
        await db.SaveChangesAsync();
        await audit.LogAsync(userId, $"data_request_{type.ToString().ToLower()}", $"requestId={request.Id}", "pending");

        var message = type == DataRequestType.Export
            ? "Your data export request has been received. You will be notified when it is ready (up to 45 days)."
            : "Your deletion request has been received and will be processed within 45 days as required by CCPA.";

        return Map(request, message);
    }

    public async Task RecordConsentAsync(string userId, string consentType, bool granted, string? ipAddress = null)
    {
        db.ConsentRecords.Add(new ConsentRecord
        {
            UserId      = userId,
            ConsentType = consentType,
            Granted     = granted,
            IpAddress   = ipAddress,
            CreatedAt   = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        await audit.LogAsync(userId, "consent_recorded", $"type={consentType} granted={granted}", "recorded", ipAddress);
    }

    public async Task<IReadOnlyList<ConsentRecord>> GetConsentsAsync(string userId)
        => await db.ConsentRecords
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();

    public async Task<IReadOnlyList<DataSubjectRequest>> GetRequestsAsync(string userId)
        => await db.DataSubjectRequests
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

    private static DataSubjectRequestResult Map(DataSubjectRequest r, string message) => new()
    {
        RequestId   = r.Id,
        UserId      = r.UserId,
        RequestType = r.RequestType,
        Status      = r.Status,
        Message     = message,
        CreatedAt   = r.CreatedAt,
    };
}
