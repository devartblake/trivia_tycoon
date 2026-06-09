using ComplianceService.Data;
using Microsoft.EntityFrameworkCore;

namespace ComplianceService.Services;

public interface IAuditLogService
{
    Task LogAsync(string userId, string eventType, string details, string outcome, string? ipAddress = null);
    Task<IReadOnlyList<AuditLogEntry>> GetLogAsync(string userId, DateTime? from = null, DateTime? to = null, int limit = 100);
}

public class AuditLogService(ComplianceDbContext db) : IAuditLogService
{
    public async Task LogAsync(string userId, string eventType, string details, string outcome, string? ipAddress = null)
    {
        db.AuditLog.Add(new AuditLogEntry
        {
            UserId    = userId,
            EventType = eventType,
            Details   = details,
            Outcome   = outcome,
            IpAddress = ipAddress,
            CreatedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
    }

    public async Task<IReadOnlyList<AuditLogEntry>> GetLogAsync(
        string userId, DateTime? from = null, DateTime? to = null, int limit = 100)
    {
        var query = db.AuditLog.Where(e => e.UserId == userId);
        if (from.HasValue) query = query.Where(e => e.CreatedAt >= from.Value);
        if (to.HasValue)   query = query.Where(e => e.CreatedAt <= to.Value);
        return await query.OrderByDescending(e => e.CreatedAt).Take(limit).ToListAsync();
    }
}
