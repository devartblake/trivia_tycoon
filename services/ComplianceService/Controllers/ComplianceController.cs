using ComplianceService.Services;
using Microsoft.AspNetCore.Mvc;

namespace ComplianceService.Controllers;

[ApiController]
[Route("api/compliance")]
public class ComplianceController(IComplianceOrchestrationService compliance) : ControllerBase
{
    [HttpGet("status/{userId}")]
    public async Task<IActionResult> GetStatus(string userId)
    {
        if (string.IsNullOrWhiteSpace(userId)) return BadRequest("userId is required");
        return Ok(await compliance.GetStatusAsync(userId));
    }
}
