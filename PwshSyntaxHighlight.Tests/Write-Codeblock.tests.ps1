Import-Module "$PSScriptRoot\..\PwshSyntaxHighlight.psd1" -Force
$preTestThemes = $null

Describe "Testing Write-Codeblock function" {

    InModuleScope 'PwshSyntaxHighlight' {
        
        BeforeAll {
            $preTestThemes = $script:Themes
            $script:Themes = @{
                Github = @{
                    ForegroundRgb = @{ R = 255; G = 0; B = 0 }
                    Generic = @{ R = 0; G = 255; B = 0 }
                    BackgroundRgb = @{ R = 255; G = 255; B = 255 }
                }
                Matrix = @{
                    ForegroundRgb = @{ R = 0; G = 0; B = 255 }
                    Generic = @{ R = 0; G = 255; B = 0 }
                    BackgroundRgb = @{ R = 255; G = 255; B = 255 }
                }
            };
        }

        AfterAll {
            $script:Themes = $preTestThemes
        }

        It "Should write a simple codeblock with no line numbers" {
            $text = "Write-Output 'Hello, World!'"
            Write-Codeblock -Text $text
            $location = $Host.UI.RawUI.CursorPosition
            $rectangle = New-Object System.Management.Automation.Host.Rectangle 0,($location.Y - 1),($text.Length - 1),($location.Y - 1)
            $buffer = $Host.UI.RawUI.GetBufferContents($rectangle)
            $outputText = ($buffer | Select-Object -ExpandProperty Character) -join ''
            $outputText | Should -eq $text
        }

        It "Should write a codeblock with line numbers" {
            $text = "Write-Output 'Hello, Syntax Highlighter!'"
            Write-Codeblock -Text $text -ShowLineNumbers
            $location = $Host.UI.RawUI.CursorPosition
            $rectangle = New-Object System.Management.Automation.Host.Rectangle 0,($location.Y - 1),($text.Length + 1),($location.Y - 1)
            $buffer = $Host.UI.RawUI.GetBufferContents($rectangle)
            $outputText = ($buffer | Select-Object -ExpandProperty Character) -join ''
            $outputText | Should -eq "1 $text"
        }

        It "Should write a codeblock with line numbers padded correctly to compensate for gutter size required for line numbers" {
            $repeatedLine = "Write-Output 'Hello, Syntax Highlighter!'"
            $text = ("$repeatedLine`n" * 10).Trim()
            Write-Codeblock -Text $text -ShowLineNumbers
            $location = $Host.UI.RawUI.CursorPosition
            $rectangle = New-Object System.Management.Automation.Host.Rectangle 0,($location.Y - 1),($repeatedLine.Length + 2),($location.Y - 1)
            $buffer = $Host.UI.RawUI.GetBufferContents($rectangle)
            $outputText = ($buffer | Select-Object -ExpandProperty Character) -join ''
            $outputText | Should -eq "10 $repeatedLine"
        }

        It "Should write a codeblock with syntax highlighting" {
            $text = "Write-Output 'I am syntax highlighted'"
            Write-Codeblock -Text $text -SyntaxHighlight
            $location = $Host.UI.RawUI.CursorPosition
            $rectangle = New-Object System.Management.Automation.Host.Rectangle 0,($location.Y - 1),($repeatedLine.Length + 2),($location.Y - 1)
            $buffer = $Host.UI.RawUI.GetBufferContents($rectangle)
            $buffer[0,0].ForegroundColor | Should -eq "Green"
        }

        It "Should write a codeblock without syntax highlighting" {
            $text = "Write-Output 'I am not syntax highlighted'"
            Write-Codeblock -Text $text
            $location = $Host.UI.RawUI.CursorPosition
            $rectangle = New-Object System.Management.Automation.Host.Rectangle 0,($location.Y - 1),($repeatedLine.Length + 2),($location.Y - 1)
            $buffer = $Host.UI.RawUI.GetBufferContents($rectangle)
            $buffer[0,0].ForegroundColor | Should -not -eq "Green"
        }

        It "Should write a codeblock with valid theme" {
            Write-Codeblock -Text "Write-Output 'Hello, World!'" -Theme "Github"
        }

        It "Should write a codeblock when code is provided as a pipeline parameter" {
            "Write-Output 'Hello, World!'" | Write-Codeblock
        }

        It "Should throw error when unsupported theme is provided" {
            $errorRecord = { Write-Codeblock -Text "Write-Output 'Hello, World!'" -Theme "UnsupportedTheme" } | Should -Throw -PassThru
            $errorRecord.Exception.Message | Should -Match "Cannot validate argument on parameter 'Theme'"
        }

        It "Should throw error when no code text is provided" {
            $errorRecord = { Write-Codeblock $null } | Should -Throw -PassThru
            $errorRecord.Exception.Message | Should -Match "Cannot bind argument to parameter 'Text' because it is null.|Cannot bind argument to parameter 'Text' because it is an empty string."
        }

        It "Should throw error when no code text is provided as a pipeline parameter" {
            $errorRecord = { Write-Codeblock $null } | Should -Throw -PassThru
            $errorRecord.Exception.Message | Should -Match "Cannot bind argument to parameter 'Text' because it is null.|Cannot bind argument to parameter 'Text' because it is an empty string."
        }
    }
}