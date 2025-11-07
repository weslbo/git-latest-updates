using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Processing GitHub diff aggregation request..."

# Extract query parameters
$repo = $Request.Query.repo
$since = $Request.Query.date

if (-not $repo -or -not $since) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = "Missing required query parameters: repo and date"
    })
    return
}

# Extract token from custom header 'git-token'
$token = $Request.Headers["git-token"]
if (-not $token) {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::Unauthorized
        Body = "Missing 'git-token' header"
    })
    return
}

# Prepare headers
$headers = @{
    Authorization = "token $token"
    Accept        = "application/vnd.github.v3+json"
}

# Get commits since the specified date
$commitUrl = "https://api.github.com/repos/$repo/commits?since=$since"
try {
    $commitResponse = Invoke-RestMethod -Uri $commitUrl -Headers $headers
} catch {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadGateway
        Body = "Error fetching commits: $_"
    })
    return
}

# Aggregate diffs for .md files only
$diffs = ""
foreach ($commit in $commitResponse) {
    $sha = $commit.sha
    $commitDetailsUrl = "https://api.github.com/repos/$repo/commits/$sha"

    try {
        $commitDetails = Invoke-RestMethod -Uri $commitDetailsUrl -Headers $headers
        $mdFiles = $commitDetails.files | Where-Object { $_.filename -like "*.md" }

        if ($mdFiles.Count -gt 0) {
            Write-Host "Including commit $sha with .md changes"
            $diffHeaders = @{
                Authorization = "token $token"
                Accept        = "application/vnd.github.v3.diff"
            }
            $diffText = Invoke-RestMethod -Uri $commitDetailsUrl -Headers $diffHeaders -Method Get -ContentType "application/vnd.github.v3.diff"
            $diffs += "`nCommit: $sha`n$diffText`n---`n"
        } else {
            Write-Host "Skipping commit $sha (no .md changes)"
        }
    } catch {
        $diffs += "`nCommit: $sha`n[Error fetching diff: $_]`n---`n"
    }
}

# Return the aggregated diffs
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Headers = @{ "Content-Type" = "text/plain" }
    Body = $diffs
})