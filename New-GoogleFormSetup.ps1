function New-GoogleFormSetup {
<#
 .SYNOPSIS
  Automate the creation of a Google Form with Apps Script backend deployed on GitHub Pages

 .DESCRIPTION
  This script automates the entire workflow for creating an HTML form that submits data to Google Sheets via Apps Script.
  The form is then published on GitHub Pages for public access.

  MANUAL PREREQUISITES (must be completed before running this script):
  1. Create a public GitHub repository at github.com
  2. Create a dedicated Gmail account for the app (e.g., stmarychurchchessclub@gmail.com)
  3. Set up GitHub authentication: configure git credentials locally
  4. Set up Google API credentials:
     - Go to Google Cloud Console (console.cloud.google.com)
     - Create a new project
     - Enable Google Sheets API and Google Apps Script API
     - Create OAuth 2.0 credentials (Desktop application type)
     - Save the credentials JSON file
  5. Have Git installed and in PATH

 .PARAMETER GitHubRepoUrl
  The HTTPS clone URL of your public GitHub repository
  Example: https://github.com/username/repo-name.git

 .PARAMETER GoogleApiCredentialsPath
  Path to the Google API credentials JSON file (OAuth 2.0 credentials)

 .PARAMETER AppName
  Display name for your form/app (e.g., "Chess Training Signup")
  This will be used in the Google Sheet name and form title

 .PARAMETER FormFields
  Array of field objects defining your form fields
  Example: @(
    @{Name='name'; Label='Full Name'; Type='text'; Required=$true},
    @{Name='email'; Label='Email'; Type='email'; Required=$true}
  )

 .PARAMETER LocalPath
  Local folder path where the repository will be cloned
  Default: $env:TEMP\GoogleFormSetup

 .PARAMETER GitHubUsername
  Your GitHub username (used for GitHub Pages URL generation)

 .EXAMPLE
  $Fields = @(
    @{Name='name'; Label='Full Name'; Type='text'; Required=$true},
    @{Name='grade'; Label='Grade'; Type='select'; Required=$true; Options=@('K','1','2','3','4','5')},
    @{Name='email'; Label='Email'; Type='email'; Required=$true},
    @{Name='phone'; Label='Phone'; Type='tel'; Required=$true}
  )

  New-GoogleFormSetup -GitHubRepoUrl 'https://github.com/myusername/myform.git' `
    -GoogleApiCredentialsPath 'C:\credentials.json' `
    -AppName 'Chess Training Signup' `
    -FormFields $Fields `
    -GitHubUsername 'myusername' `
    -Verbose

 .OUTPUTS
  Returns an object with:
    DeploymentUrl - The Apps Script web app URL to use in the HTML form
    GitHubPagesUrl - The public URL where the form is hosted
    SheetId - The Google Sheet ID where form data is stored
    LocalPath - Path to the cloned repository

 .LINK
  https://github.com/Sambsamb/StMaryChessClub/blob/main/GOOGLE_FORM_SETUP.md

 .NOTES
  Script by Sam Boutros
  v0.1 - 18 June 2026 - Initial version

  DEPENDENCIES:
  - PowerShell 5.0+
  - Git (in PATH)
  - Google Cloud Project with Sheets API and Apps Script API enabled
  - OAuth 2.0 credentials JSON file

  LIMITATIONS:
  - Google API authentication currently requires manual setup
  - Apps Script deployment authorization may require manual browser interaction
  - GitHub authentication requires pre-configured git credentials
#>

    [CmdletBinding(ConfirmImpact='Medium')]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
            [String]$GitHubRepoUrl,
        [Parameter(Mandatory=$true, Position=1)]
            [String]$GoogleApiCredentialsPath,
        [Parameter(Mandatory=$true, Position=2)]
            [String]$AppName,
        [Parameter(Mandatory=$true, Position=3)]
            [Array]$FormFields,
        [Parameter(Mandatory=$false, Position=4)]
            [String]$LocalPath = "$env:TEMP\GoogleFormSetup_$(Get-Random)",
        [Parameter(Mandatory=$true, Position=5)]
            [String]$GitHubUsername,
        [Parameter(Mandatory=$false)]
            [String]$LogFile = "$env:TEMP\GoogleFormSetup_$(Get-Date -Format 'ddMMMyyyy-HHmm').log"
    )

    Begin {
        Write-Log "Google Form Setup Automation Started" Green $LogFile
        Write-Log "App Name: $AppName" Cyan $LogFile
        Write-Log "GitHub Repo: $GitHubRepoUrl" Cyan $LogFile

        # Validate prerequisites
        Write-Log "Validating prerequisites..." Yellow $LogFile

        if (-not (Test-Path $GoogleApiCredentialsPath)) {
            Write-Log 'ERROR: Google API credentials file not found at',$GoogleApiCredentialsPath Magenta,Yellow
            break
        }

        if (-not (Get-Command git -EA 0)) {
            Write-Log 'ERROR: Git is not installed or not in PATH' Magenta
            break
        }

        Write-Log "Prerequisites validated successfully" Green $LogFile
    }

    Process {
        try {
            # Step 1: Clone GitHub Repository
            Write-Log "Step 1: Cloning GitHub repository..." Yellow $LogFile
            if (Test-Path $LocalPath) {
                Remove-Item -Path $LocalPath -Recurse -Force -Confirm:$false
            }
            New-Item -Path $LocalPath -ItemType Directory -Force -EA 0 | Out-Null

            Push-Location $LocalPath
            & git clone $GitHubRepoUrl . 2>&1 | ForEach-Object { Write-Verbose $_ }
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to clone GitHub repository"
            }
            Write-Log "Repository cloned successfully to $LocalPath" Green $LogFile

            # Step 2: Create Google Sheet
            Write-Log "Step 2: Creating Google Sheet..." Yellow $LogFile
            $SheetName = "$AppName - $(Get-Date -Format 'yyyy-MM-dd')"
            Write-Log "Sheet name: $SheetName" Cyan $LogFile

            # Note: Full Google Sheet creation via API requires authentication setup
            Write-Log "MANUAL STEP: Google Sheet must be created via Google Drive UI at this time" Yellow $LogFile
            Write-Log "Created sheet should be named: $SheetName" Cyan $LogFile
            Write-Log "First row should contain headers matching your form fields" Cyan $LogFile

            $SheetId = Read-Host "Enter the Google Sheet ID (from the URL docs.google.com/spreadsheets/d/[SHEET_ID])"
            if (-not $SheetId) {
                throw "Sheet ID is required"
            }
            Write-Log "Using Sheet ID: $SheetId" Green $LogFile

            # Step 3: Create HTML Form
            Write-Log "Step 3: Creating HTML form..." Yellow $LogFile
            $HtmlContent = New-GoogleFormHtml -AppName $AppName -FormFields $FormFields
            $HtmlPath = Join-Path $LocalPath "index.html"
            $HtmlContent | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force
            Write-Log "HTML form created at $HtmlPath" Green $LogFile

            # Step 4: Create and Deploy Apps Script
            Write-Log "Step 4: Preparing Apps Script code..." Yellow $LogFile
            $ScriptContent = New-AppsScriptCode -SheetId $SheetId -FormFields $FormFields
            Write-Log "Apps Script code generated" Green $LogFile

            Write-Log "MANUAL STEP: Apps Script deployment required" Yellow $LogFile
            Write-Log "1. Go to Google Drive" Cyan $LogFile
            Write-Log "2. Create new Google Apps Script" Cyan $LogFile
            Write-Log "3. Copy and paste the following code:" Cyan $LogFile
            Write-Log "---APPS SCRIPT CODE START---" Cyan $LogFile
            Write-Log $ScriptContent Cyan $LogFile
            Write-Log "---APPS SCRIPT CODE END---" Cyan $LogFile
            Write-Log "4. Click Deploy > New deployment > Web app" Cyan $LogFile
            Write-Log "5. Execute as: your app account" Cyan $LogFile
            Write-Log "6. Who has access: Anyone" Cyan $LogFile
            Write-Log "7. Click Deploy and authorize when prompted" Cyan $LogFile

            $DeploymentUrl = Read-Host "Enter the Apps Script web app deployment URL (from macros/s/...../exec)"
            if (-not $DeploymentUrl -or -not $DeploymentUrl.StartsWith('https://script.google.com')) {
                throw "Invalid deployment URL"
            }
            Write-Log "Using Deployment URL: $DeploymentUrl" Green $LogFile

            # Step 5: Update HTML with Deployment URL
            Write-Log "Step 5: Updating HTML with deployment URL..." Yellow $LogFile
            $HtmlContent = Get-Content -Path $HtmlPath -Raw
            $HtmlContent = $HtmlContent -replace "DEPLOYMENT_URL_PLACEHOLDER", $DeploymentUrl
            $HtmlContent | Out-File -FilePath $HtmlPath -Encoding UTF8 -Force
            Write-Log "HTML form updated with deployment URL" Green $LogFile

            # Step 6: Create .gitignore
            Write-Log "Step 6: Creating .gitignore..." Yellow $LogFile
            $GitIgnore = @"
*
!index.html
!.gitignore
"@
            $GitIgnore | Out-File -FilePath (Join-Path $LocalPath ".gitignore") -Encoding UTF8 -Force
            Write-Log ".gitignore created" Green $LogFile

            # Step 7: Commit and Push
            Write-Log "Step 7: Committing and pushing to GitHub..." Yellow $LogFile
            & git add index.html .gitignore 2>&1 | ForEach-Object { Write-Verbose $_ }
            & git commit -m "Initial Google Form setup - $AppName" 2>&1 | ForEach-Object { Write-Verbose $_ }
            & git push 2>&1 | ForEach-Object { Write-Verbose $_ }
            if ($LASTEXITCODE -ne 0) {
                Write-Log "WARNING: Git push may have failed. Check the output above." Yellow $LogFile
            } else {
                Write-Log "Changes pushed to GitHub successfully" Green $LogFile
            }

            # Step 8: Enable GitHub Pages
            Write-Log "Step 8: Enabling GitHub Pages..." Yellow $LogFile
            Write-Log "MANUAL STEP: Enable GitHub Pages in repository settings" Yellow $LogFile
            Write-Log "1. Go to GitHub: $GitHubRepoUrl" Cyan $LogFile
            Write-Log "2. Click Settings > Pages" Cyan $LogFile
            Write-Log "3. Select 'main' branch as source" Cyan $LogFile
            Write-Log "4. Save" Cyan $LogFile

            $GitHubPagesUrl = "https://$GitHubUsername.github.io/$($GitHubRepoUrl.Split('/')[-1].Replace('.git',''))"
            Write-Log "Your form will be available at: $GitHubPagesUrl" Green $LogFile

            Pop-Location

            # Return results
            $Result = [PSCustomObject]@{
                DeploymentUrl = $DeploymentUrl
                GitHubPagesUrl = $GitHubPagesUrl
                SheetId = $SheetId
                LocalPath = $LocalPath
                AppName = $AppName
            }

            Write-Log "Google Form Setup completed successfully!" Green $LogFile
            Write-Log "Summary:" Cyan $LogFile
            Write-Log "  GitHub Pages URL: $GitHubPagesUrl" Cyan $LogFile
            Write-Log "  Sheet ID: $SheetId" Cyan $LogFile
            Write-Log "  Local Path: $LocalPath" Cyan $LogFile
            Write-Log "  Log File: $LogFile" Cyan $LogFile

            return $Result

        } catch {
            Write-Log 'ERROR:',$_.Exception.Message Magenta,Yellow $LogFile
            Write-Log $_.ScriptStackTrace Yellow $LogFile
            break
        } finally {
            if ((Get-Location).Path -ne $PSScriptRoot) {
                Pop-Location -EA 0
            }
        }
    }

    End {
        Write-Log "Script completed" Cyan $LogFile
    }
}

function New-GoogleFormHtml {
<#
 .SYNOPSIS
  Generate HTML form code

 .NOTES
  Helper function for New-GoogleFormSetup
#>
    Param(
        [String]$AppName,
        [Array]$FormFields
    )

    $FieldsHtml = ""
    foreach ($Field in $FormFields) {
        $Required = $Field.Required ? 'required' : ''
        $Label = $Field.Label
        $Name = $Field.Name
        $Type = $Field.Type

        if ($Type -eq 'select') {
            $OptionsHtml = ""
            $OptionsHtml += "                    <option value="""">-- Select $Label --</option>`n"
            foreach ($Option in $Field.Options) {
                $OptionsHtml += "                    <option value=""$Option"">$Option</option>`n"
            }
            $FieldsHtml += @"
            <div class="form-group">
                <label for="$Name">$Label <span class="required">*</span></label>
                <select id="$Name" name="$Name" $Required>
$OptionsHtml                </select>
            </div>

"@
        } else {
            $FieldsHtml += @"
            <div class="form-group">
                <label for="$Name">$Label <span class="required">*</span></label>
                <input type="$Type" id="$Name" name="$Name" placeholder="Enter $Label" $Required>
            </div>

"@
        }
    }

    $Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$AppName</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }

        .container {
            background-color: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
            padding: 40px;
            max-width: 500px;
            width: 100%;
        }

        .header {
            text-align: center;
            margin-bottom: 30px;
        }

        .header h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }

        .form-group {
            margin-bottom: 20px;
        }

        label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
            font-size: 14px;
        }

        input,
        select {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 5px;
            font-size: 14px;
            font-family: inherit;
            transition: border-color 0.3s;
        }

        input:focus,
        select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        button {
            width: 100%;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            margin-top: 10px;
        }

        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }

        .success-message {
            display: none;
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #28a745;
        }

        .error-message {
            display: none;
            background-color: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #f5c6cb;
        }

        .required {
            color: #e74c3c;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$AppName</h1>
        </div>

        <div id="successMessage" class="success-message">
            Thank you for submitting! We appreciate your participation.
        </div>
        <div id="errorMessage" class="error-message"></div>

        <form id="signupForm">
$FieldsHtml            <button type="submit" id="submitBtn">Submit</button>
        </form>
    </div>

    <script>
        const GOOGLE_APPS_SCRIPT_URL = 'DEPLOYMENT_URL_PLACEHOLDER';

        const form = document.getElementById('signupForm');
        const submitBtn = document.getElementById('submitBtn');
        const successMessage = document.getElementById('successMessage');
        const errorMessage = document.getElementById('errorMessage');

        form.addEventListener('submit', function(e) {
            e.preventDefault();

            successMessage.style.display = 'none';
            errorMessage.style.display = 'none';

            if (!form.checkValidity()) {
                errorMessage.textContent = 'Please fill out all required fields correctly.';
                errorMessage.style.display = 'block';
                return;
            }

            submitBtn.disabled = true;
            submitBtn.textContent = 'Submitting...';

            const formData = new FormData();
            const fields = new FormData(form);
            for (let [key, value] of fields.entries()) {
                formData.append(key, value);
            }
            formData.append('timestamp', new Date().toISOString());

            fetch(GOOGLE_APPS_SCRIPT_URL, {
                method: 'POST',
                body: formData
            })
            .then(() => {
                successMessage.style.display = 'block';
                form.reset();
                submitBtn.disabled = false;
                submitBtn.textContent = 'Submit';
                setTimeout(() => {
                    successMessage.style.display = 'none';
                }, 5000);
            })
            .catch((error) => {
                console.error('Error:', error);
                errorMessage.textContent = 'Error submitting form. Please try again.';
                errorMessage.style.display = 'block';
                submitBtn.disabled = false;
                submitBtn.textContent = 'Submit';
            });
        });
    </script>
</body>
</html>
"@

    return $Html
}

function New-AppsScriptCode {
<#
 .SYNOPSIS
  Generate Apps Script code

 .NOTES
  Helper function for New-GoogleFormSetup
#>
    Param(
        [String]$SheetId,
        [Array]$FormFields
    )

    $FieldNames = $FormFields | ForEach-Object { $_.Name }
    $HeaderRow = @("Timestamp") + $FieldNames
    $HeaderJson = $HeaderRow | ConvertTo-Json

    $FieldExtraction = ""
    foreach ($Field in $FormFields) {
        $FieldExtraction += "    const $($Field.Name) = e.parameter.$($Field.Name) || '';`n"
    }

    $FieldArray = "[timestamp, " + ($FieldNames -join ", ") + "]"

    $Script = @"
const SPREADSHEET_ID = '$SheetId';

function doPost(e) {
  try {
    if (!e || !e.parameter) {
      Logger.log('Error: Request object or parameter is missing');
      return ContentService.createTextOutput('Error: No data received');
    }

    Logger.log('Request received. Parameters: ' + JSON.stringify(e.parameter));

    // Get form parameters (from FormData)
$FieldExtraction    const timestamp = e.parameter.timestamp || new Date().toISOString();

    Logger.log('Received data - ' + JSON.stringify(e.parameter));

    // Get the active spreadsheet and sheet
    const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
    let sheet = spreadsheet.getSheets()[0];

    // If sheet is empty, add headers
    if (sheet.getLastRow() === 0) {
      const headers = $($HeaderJson -replace '"', "'");
      sheet.appendRow(headers);
      Logger.log('Added headers to sheet');
    }

    // Append the new row with form data
    const newRow = $FieldArray;
    sheet.appendRow(newRow);
    Logger.log('Row appended successfully');

    // Return success response
    return ContentService.createTextOutput('Success');

  } catch (error) {
    // Log error and return error response
    Logger.log('Error: ' + error.toString());
    return ContentService.createTextOutput('Error: ' + error.toString());
  }
}

// Test function
function testScript() {
  const payload = {
    timestamp: new Date().toISOString(),
$($FieldNames | ForEach-Object { "    $_: 'Test $_'," })
  };

  const options = {
    method: 'post',
    payload: payload,
    muteHttpExceptions: true
  };

  const response = UrlFetchApp.fetch(ScriptApp.getService().getUrl(), options);
  Logger.log('Test response: ' + response.getContentText());
}
"@

    return $Script
}

# Helper function from global CLAUDE.md
function Write-Log {
    [CmdletBinding(ConfirmImpact='Low')]
    Param(
        [Parameter(Mandatory=$false, ValueFromPipeLine=$true, Position=0)][String[]]$String,
        [Parameter(Mandatory=$false, Position=1)][String[]]$Color,
        [Parameter(Mandatory=$false, Position=2)][String]$LogFile,
        [Parameter(Mandatory=$false, Position=3)][Switch]$NoNewLine
    )

    if ($String) {
        $i=0
        foreach ($item in $String) {
            try {
                Write-Host "$item " -ForegroundColor $Color[$i] -NoNewline -EA 1
            } catch {
                Write-Host "$item " -NoNewline
            }
            $i++
        }
        if (-not $NoNewLine) { Write-Host ' ' }

        if ($LogFile) {
            try {
                "$(Get-Date -format 'dd MMMM yyyy hh:mm:ss tt'): $($String -join ' ')" |
                    Out-File -Filepath $Logfile -Append -ErrorAction Stop
            } catch {
                Write-Warning "Write-Log: Bad LogFile name ($LogFile). Will not save input string(s) to log file.."
            }
        }
    }
}
