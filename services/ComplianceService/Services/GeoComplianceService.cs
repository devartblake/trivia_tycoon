using ComplianceService.Data;
using ComplianceService.Models;
using Microsoft.Extensions.Options;

namespace ComplianceService.Services;

public interface IGeoComplianceService
{
    Task<GeoCheckResult> CheckAsync(string userId, string stateCode);
}

public class GeoComplianceService(
    ComplianceDbContext db,
    IAuditLogService audit,
    IOptions<ComplianceOptions> opts) : IGeoComplianceService
{
    private readonly ComplianceOptions _opts = opts.Value;

    public async Task<GeoCheckResult> CheckAsync(string userId, string stateCode)
    {
        var state = stateCode.Trim().ToUpperInvariant();
        var restricted = _opts.RestrictedStates.Contains(state);
        var geoStatus  = restricted ? GeoStatus.Restricted : GeoStatus.Allowed;

        var cr = await db.ComplianceRecords.FindAsync(userId);
        if (cr is null)
        {
            cr = new ComplianceRecord { UserId = userId };
            db.ComplianceRecords.Add(cr);
        }
        cr.GeoStatus     = geoStatus;
        cr.LastStateCode = state;
        cr.UpdatedAt     = DateTime.UtcNow;
        await db.SaveChangesAsync();

        await audit.LogAsync(userId, "geo_check", $"state={state}", geoStatus.ToString());

        return new GeoCheckResult
        {
            UserId            = userId,
            StateCode         = state,
            GeoStatus         = geoStatus,
            IsAllowed         = !restricted,
            RestrictionReason = restricted
                ? $"Prize games with crypto payouts are not available in {state}. See Compliance.RestrictedStates."
                : null,
        };
    }
}
