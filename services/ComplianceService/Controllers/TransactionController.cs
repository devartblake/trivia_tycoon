using ComplianceService.Models;
using ComplianceService.Services;
using Microsoft.AspNetCore.Mvc;

namespace ComplianceService.Controllers;

[ApiController]
[Route("api/transaction")]
public class TransactionController(
    IAmlService aml,
    IAgeVerificationService age,
    IGeoComplianceService geo) : ControllerBase
{
    [HttpPost("check")]
    public async Task<IActionResult> CheckTransaction([FromBody] TransactionCheckRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId)) return BadRequest("userId is required");
        if (request.Amount <= 0)                       return BadRequest("amount must be positive");
        return Ok(await aml.CheckTransactionAsync(request.UserId, request.Amount, request.Network, request.TransactionType));
    }

    [HttpPost("age-verify")]
    public async Task<IActionResult> VerifyAge([FromBody] AgeVerificationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId)) return BadRequest("userId is required");
        return Ok(await age.VerifyAsync(request.UserId, request.DateOfBirth));
    }

    [HttpPost("geo-check")]
    public async Task<IActionResult> GeoCheck([FromBody] GeoCheckRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))    return BadRequest("userId is required");
        if (string.IsNullOrWhiteSpace(request.StateCode)) return BadRequest("stateCode is required");
        return Ok(await geo.CheckAsync(request.UserId, request.StateCode));
    }
}
