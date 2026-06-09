using ComplianceService.Data;
using ComplianceService.Models;

namespace ComplianceService.Services;

public interface IComplianceOrchestrationService
{
    Task<ComplianceStatus> GetStatusAsync(string userId);
}

public class ComplianceOrchestrationService(ComplianceDbContext db) : IComplianceOrchestrationService
{
    public async Task<ComplianceStatus> GetStatusAsync(string userId)
    {
        var cr = await db.ComplianceRecords.FindAsync(userId);

        if (cr is null)
        {
            return new ComplianceStatus
            {
                UserId          = userId,
                KycStatus       = KycStatus.NotStarted,
                AgeStatus       = AgeStatus.Unknown,
                GeoStatus       = GeoStatus.Unchecked,
                AmlStatus       = AmlStatus.Clear,
                ConsentStatus   = ConsentStatus.NotGiven,
                CanUseCrypto    = false,
                CanReceivePrizes = false,
                CanCollectData  = false,
                RequiredActions = ["kyc", "age_verification", "consent", "geo_check"],
            };
        }

        // All four gates must pass to allow crypto operations
        var canUseCrypto = cr.KycStatus     == KycStatus.Approved
                        && cr.AgeStatus     == AgeStatus.Adult
                        && cr.GeoStatus     != GeoStatus.Blocked
                        && cr.GeoStatus     != GeoStatus.Restricted
                        && cr.AmlStatus     == AmlStatus.Clear;

        var canReceivePrizes = cr.AgeStatus != AgeStatus.CoppaMinor
                            && cr.AgeStatus != AgeStatus.Unknown
                            && cr.AgeStatus != AgeStatus.Minor
                            && cr.GeoStatus != GeoStatus.Blocked
                            && cr.GeoStatus != GeoStatus.Restricted;

        var canCollectData = cr.AgeStatus     != AgeStatus.CoppaMinor
                          && cr.ConsentStatus != ConsentStatus.NotGiven;

        return new ComplianceStatus
        {
            UserId           = userId,
            KycStatus        = cr.KycStatus,
            AgeStatus        = cr.AgeStatus,
            GeoStatus        = cr.GeoStatus,
            AmlStatus        = cr.AmlStatus,
            ConsentStatus    = cr.ConsentStatus,
            LastStateCode    = cr.LastStateCode,
            CanUseCrypto     = canUseCrypto,
            CanReceivePrizes = canReceivePrizes,
            CanCollectData   = canCollectData,
            RequiredActions  = BuildRequiredActions(cr),
            LastUpdated      = cr.UpdatedAt,
        };
    }

    private static List<string> BuildRequiredActions(ComplianceRecord cr)
    {
        var actions = new List<string>();
        if (cr.KycStatus is KycStatus.NotStarted or KycStatus.Rejected or KycStatus.Expired)
            actions.Add("kyc");
        if (cr.AgeStatus == AgeStatus.Unknown)
            actions.Add("age_verification");
        if (cr.ConsentStatus == ConsentStatus.NotGiven)
            actions.Add("consent");
        if (cr.GeoStatus == GeoStatus.Unchecked)
            actions.Add("geo_check");
        return actions;
    }
}
