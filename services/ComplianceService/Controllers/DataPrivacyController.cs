using ComplianceService.Models;
using ComplianceService.Services;
using Microsoft.AspNetCore.Mvc;

namespace ComplianceService.Controllers;

[ApiController]
[Route("api/privacy")]
public class DataPrivacyController(IDataPrivacyService privacy, IAuditLogService audit) : ControllerBase
{
    [HttpPost("export/{userId}")]
    public async Task<IActionResult> RequestExport(string userId) =>
        Ok(await privacy.RequestExportAsync(userId));

    [HttpDelete("{userId}")]
    public async Task<IActionResult> RequestDeletion(string userId) =>
        Ok(await privacy.RequestDeletionAsync(userId));

    [HttpPost("consent")]
    public async Task<IActionResult> RecordConsent([FromBody] ConsentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))      return BadRequest("userId is required");
        if (string.IsNullOrWhiteSpace(request.ConsentType)) return BadRequest("consentType is required");
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        await privacy.RecordConsentAsync(request.UserId, request.ConsentType, request.Granted, ip);
        return Ok(new { recorded = true });
    }

    [HttpGet("consents/{userId}")]
    public async Task<IActionResult> GetConsents(string userId) =>
        Ok(await privacy.GetConsentsAsync(userId));

    [HttpGet("audit/{userId}")]
    public async Task<IActionResult> GetAuditLog(
        string userId,
        [FromQuery] DateTime? from  = null,
        [FromQuery] DateTime? to    = null,
        [FromQuery] int       limit = 100) =>
        Ok(await audit.GetLogAsync(userId, from, to, Math.Clamp(limit, 1, 500)));
}
