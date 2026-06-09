using ComplianceService.Models;
using ComplianceService.Services;
using Microsoft.AspNetCore.Mvc;

namespace ComplianceService.Controllers;

[ApiController]
[Route("api/kyc")]
public class KycController(IKycService kyc) : ControllerBase
{
    [HttpPost("initiate")]
    public async Task<IActionResult> Initiate([FromBody] KycInitiateRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.UserId))    return BadRequest("userId is required");
        if (string.IsNullOrWhiteSpace(request.ReturnUrl)) return BadRequest("returnUrl is required");
        return Ok(await kyc.InitiateVerificationAsync(request.UserId, request.ReturnUrl));
    }

    [HttpGet("status/{userId}")]
    public async Task<IActionResult> GetStatus(string userId) =>
        Ok(await kyc.GetStatusAsync(userId));

    // Stripe calls this endpoint directly — no JWT auth, verified by webhook signature instead
    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook()
    {
        using var reader    = new StreamReader(Request.Body);
        var payload         = await reader.ReadToEndAsync();
        var stripeSignature = Request.Headers["Stripe-Signature"].FirstOrDefault() ?? "";

        try
        {
            await kyc.HandleStripeWebhookAsync(payload, stripeSignature);
            return Ok();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
