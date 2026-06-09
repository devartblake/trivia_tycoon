using ComplianceService.Data;
using ComplianceService.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace ComplianceService.Services;

public interface IAmlService
{
    Task<AmlCheckResult> CheckTransactionAsync(string userId, decimal amount, string network, string transactionType);
    Task<decimal> GetDailyTotalAsync(string userId);
}

public class AmlService(
    ComplianceDbContext db,
    IAuditLogService audit,
    IOptions<ComplianceOptions> opts) : IAmlService
{
    private readonly ComplianceOptions _opts = opts.Value;

    public async Task<AmlCheckResult> CheckTransactionAsync(
        string userId, decimal amount, string network, string transactionType)
    {
        var dailyTotal    = await GetDailyTotalAsync(userId);
        var projectedDay  = dailyTotal + amount;

        AmlStatus status     = AmlStatus.Clear;
        string?   alertReason = null;

        if (amount >= _opts.AmlSingleTransactionThresholdUsd)
        {
            status      = AmlStatus.UnderReview;
            alertReason = $"Single transaction ${amount:F2} meets enhanced-review threshold ${_opts.AmlSingleTransactionThresholdUsd:F2}";
        }

        if (projectedDay >= _opts.AmlDailyThresholdUsd)
        {
            status      = AmlStatus.Flagged;
            alertReason = $"Projected daily total ${projectedDay:F2} meets or exceeds BSA CTR threshold ${_opts.AmlDailyThresholdUsd:F2}";
        }

        db.AmlRecords.Add(new AmlRecord
        {
            UserId          = userId,
            Amount          = amount,
            Network         = network,
            TransactionType = transactionType,
            Status          = status,
            AlertReason     = alertReason,
            CreatedAt       = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        await audit.LogAsync(userId, "aml_check", $"amount={amount} network={network} type={transactionType}", status.ToString());

        return new AmlCheckResult
        {
            UserId         = userId,
            AmlStatus      = status,
            IsAllowed      = status == AmlStatus.Clear,
            RequiresReview = status == AmlStatus.UnderReview,
            AlertReason    = alertReason,
            DailyTotal     = projectedDay,
        };
    }

    public async Task<decimal> GetDailyTotalAsync(string userId)
    {
        var startOfDay = DateTime.UtcNow.Date;
        return await db.AmlRecords
            .Where(r => r.UserId == userId && r.CreatedAt >= startOfDay)
            .SumAsync(r => r.Amount);
    }
}
