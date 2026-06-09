using System.Security.Cryptography;
using System.Text;
using ComplianceService.Data;
using ComplianceService.Models;
using Microsoft.Extensions.Options;

namespace ComplianceService.Services;

public interface IAgeVerificationService
{
    Task<AgeVerificationResult> VerifyAsync(string userId, DateOnly dateOfBirth);
    Task<AgeStatus> GetStatusAsync(string userId);
}

public class AgeVerificationService(
    ComplianceDbContext db,
    IAuditLogService audit,
    IOptions<ComplianceOptions> opts) : IAgeVerificationService
{
    private readonly ComplianceOptions _opts = opts.Value;

    public async Task<AgeVerificationResult> VerifyAsync(string userId, DateOnly dateOfBirth)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var age = today.Year - dateOfBirth.Year;
        if (dateOfBirth.AddYears(age) > today) age--;

        var status = age < _opts.MinAgeForCoppa
            ? AgeStatus.CoppaMinor
            : age < _opts.MinAgeForPrizes
                ? AgeStatus.Minor
                : AgeStatus.Adult;

        var dobHash = HashDob(dateOfBirth);

        var existing = await db.AgeRecords.FindAsync(userId);
        if (existing is null)
            db.AgeRecords.Add(new AgeRecord { UserId = userId });
        else
            existing.DateOfBirthHash = dobHash;

        var record = existing ?? db.AgeRecords.Local.First(r => r.UserId == userId);
        record.DateOfBirthHash   = dobHash;
        record.AgeAtVerification = age;
        record.Status            = status;
        record.VerifiedAt        = DateTime.UtcNow;

        await UpsertComplianceAgeAsync(userId, status);
        await db.SaveChangesAsync();
        await audit.LogAsync(userId, "age_verification", $"age={age}", status.ToString());

        return new AgeVerificationResult
        {
            UserId           = userId,
            AgeStatus        = status,
            IsCoppaCompliant = age >= _opts.MinAgeForCoppa,
            IsPrizeEligible  = age >= _opts.MinAgeForPrizes,
            MinAgeRequired   = _opts.MinAgeForPrizes,
        };
    }

    public async Task<AgeStatus> GetStatusAsync(string userId)
    {
        var record = await db.AgeRecords.FindAsync(userId);
        return record?.Status ?? AgeStatus.Unknown;
    }

    private static string HashDob(DateOnly dob)
    {
        var bytes = Encoding.UTF8.GetBytes(dob.ToString("yyyy-MM-dd"));
        return Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
    }

    private async Task UpsertComplianceAgeAsync(string userId, AgeStatus status)
    {
        var cr = await db.ComplianceRecords.FindAsync(userId);
        if (cr is null)
        {
            cr = new ComplianceRecord { UserId = userId };
            db.ComplianceRecords.Add(cr);
        }
        cr.AgeStatus  = status;
        cr.UpdatedAt  = DateTime.UtcNow;
    }
}
