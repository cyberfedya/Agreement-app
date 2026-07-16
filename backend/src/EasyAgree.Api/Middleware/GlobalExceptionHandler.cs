using Microsoft.AspNetCore.Diagnostics;

namespace EasyAgree.Api;

/// <summary>
/// Last-resort catch for any exception a use case didn't handle itself -
/// logs it with the request path for demo-day triage, then returns a
/// consistent ProblemDetails JSON body instead of a raw ASP.NET error page.
/// </summary>
public sealed class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        logger.LogError(
            exception, "Unhandled exception on {Method} {Path}", httpContext.Request.Method, httpContext.Request.Path);

        httpContext.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await httpContext.Response.WriteAsJsonAsync(
            new { title = "An unexpected error occurred.", status = 500 },
            cancellationToken);

        return true;
    }
}
