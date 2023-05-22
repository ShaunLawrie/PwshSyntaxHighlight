@{
    ModuleVersion = '1.0.0'
    GUID = '737bad60-8047-480d-bf3e-944f1a4576fc'
    Author = 'Shaun Lawrie'
    CompanyName = 'Shaun Lawrie'
    Copyright = '(c) Shaun Lawrie. All rights reserved.'
    Description = 'A code block renderer for PowerShell code in the terminal'
    PowerShellVersion = '5.0'
    PowerShellHostName = 'ConsoleHost'
    RootModule = 'PwshSyntaxHighlight'
    FunctionsToExport = @('Write-Codeblock' , 'Capture-Screenshot')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @("Windows", "Linux")
            LicenseUri = 'https://github.com/ShaunLawrie/PwshSyntaxHighlight/blob/main/LICENSE.md'
            ProjectUri = 'https://github.com/ShaunLawrie/PwshSyntaxHighlight'
            IconUri = 'https://shaunlawrie.com/images/pwshsyntaxhighlight.png'
        }
    }
}
