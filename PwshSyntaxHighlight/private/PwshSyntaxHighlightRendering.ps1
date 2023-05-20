function Expand-Tokens {
    <#
        .SYNOPSIS
            Split multiline tokens into "single line tokens" represented as hashtables.
        .DESCRIPTION
            Tokens can be multiline which makes rendering especially difficult when line wrapping of long tokens gets involved, it's
            easier to pre-split these multiline tokens into single line tokens before rendering them.
    #>
    param (
        [array] $Tokens
    )
    $splitTokens = @()
    if($null -eq $Tokens -or $Tokens.Count -eq 0) {
        return $splitTokens
    }
    foreach($token in $Tokens) {
        $tokenLines = $token.Text.Split("`n")
        $lineOffset = 0
        foreach($tokenLine in $tokenLines) {
            # If it's the first line this tokens column is not set to 1 it has its own x position
            $startColumnNumber = 1
            if($lineOffset -eq 0) {
                $startColumnNumber = $token.Extent.StartColumnNumber
            }
            $splitTokens += @{
                Text = $tokenLine
                Extent = @{
                    Text = $tokenLine
                    StartColumnNumber = $startColumnNumber
                    StartLineNumber = $token.Extent.StartLineNumber + $lineOffset
                }
                Kind = $token.Kind
                TokenFlags = $token.TokenFlags
                NestedTokens = @()
            }
            $lineOffset++
        }
        # Append nested tokens so they're expanded later than the parent and drawn overtop e.g. interpolated string variables
        $splitTokens += Expand-Tokens -Tokens $token.NestedTokens
    }
    return $splitTokens
}

function Get-TokenColor {
    <#
        .SYNOPSIS
            Given a syntax token provide a color based on its type.
    #>
    param (
        # The kind of token identified by the PowerShell language parser
        [System.Management.Automation.Language.TokenKind] $Kind,
        # TokenFlags identified by the PowerShell language parser
        [System.Management.Automation.Language.TokenFlags] $TokenFlags,
        # The theme to use to choose token colors
        [string] $Theme
    )
    $ForegroundRgb = switch -wildcard ($Kind) {
        "Function" { $script:Themes[$Theme].Function }
        "Generic" { $script:Themes[$Theme].Generic }
        "*String*" { $script:Themes[$Theme].String }
        "Variable" { $script:Themes[$Theme].Variable }
        "Identifier" { $script:Themes[$Theme].Identifier }
        "Number" { $script:Themes[$Theme].Number }
        default { $script:Themes[$Theme].Default }
    }
    if($TokenFlags -like "*operator*" -or $TokenFlags -like "*keyword*") {
        $ForegroundRgb = $script:Themes[$Theme].Keyword
    }
    return $ForegroundRgb
}

function Set-CursorVisible {
    <#
        .SYNOPSIS
            Shows/hides the terminal cursor to help with smoother animations.
    #>
    param (
        # Whether to show the cursor or hide it, defaults to show
        [bool] $CursorVisible = $true
    )
    try {
        [Console]::CursorVisible = $CursorVisible
    } catch {
        # Doesn't work in unit tests and it's not super necessary
    }
}

function Write-Token {
    <#
        .SYNOPSIS
            Writes colored text to the console at a specific token location.
    #>
    param (
        # The token to write, this can be a hashtable/object representing a (System.Management.Automation.Language.Token) or a real one, I'm faking it to deal with multiline tokens
        [object] $Token,
        # The text to write from an extent (System.Management.Automation.Language.InternalScriptExtent)
        [object] $Extent,
        # The terminal line to start rendering from
        [int] $TerminalLine,
        # Render the token with syntax highlighting
        [switch] $SyntaxHighlight,
        # Highlight this token in a bright overlay color for emphasis
        [switch] $Highlight,
        # The width of the gutter for this codeblock
        [int] $GutterSize,
        # The color theme to use
        [string] $Theme
    )

    $ForegroundRgb = $script:Themes[$Theme].ForegroundRgb
    $BackgroundRgb = $script:Themes[$Theme].BackgroundRgb

    if($Highlight) {
        $ForegroundRgb = $script:Themes[$Theme].HighlightRgb
    }

    if(!$Extent) {
        $Extent = $Token.Extent
    }

    $text = $Extent.Text
    $column = $Extent.StartColumnNumber

    $colorEscapeCode = ""
    if($SyntaxHighlight -and $null -ne $Token) {
        $ForegroundRgb = Get-TokenColor -Kind $Token.Kind -TokenFlags $Token.TokenFlags -Theme $Theme
    }
    $colorEscapeCode += "$([Char]27)[38;2;{0};{1};{2}m" -f $ForegroundRgb.R, $ForegroundRgb.G, $ForegroundRgb.B
    if($BackgroundRgb) {
        $colorEscapeCode += "$([Char]27)[48;2;{0};{1};{2}m" -f $BackgroundRgb.R, $BackgroundRgb.G, $BackgroundRgb.B
    }

    $consoleWidth = $Host.UI.RawUI.WindowSize.Width - $GutterSize
    
    try {
        $initialCursorSetting = [Console]::CursorVisible
    } catch {
        $initialCursorSetting = $true
    }
    $initialCursorPosition = $Host.UI.RawUI.CursorPosition
    Set-CursorVisible $false
    try {
        $textToRender = @()
        # Overruns are parts of this extent that extend beyond the width of the terminal and need their own line wrapping
        $overrunText = @()
        # This extent might be on a wrapped part of this line, make sure to find the correct start point
        $columnIndex = $Column - 1
        $wrappedLineIndex = [Math]::Floor($columnIndex / $consoleWidth)
        $x = ($columnIndex % $consoleWidth) + $GutterSize
        $y = $wrappedLineIndex
        # Handle extent running beyond the width of the terminal
        if(($x + $text.Length) -gt ($consoleWidth + $GutterSize)) {
            $fullExtentLine = $text
            $endOfTextOnCurrentLine = $consoleWidth - $x + $GutterSize
            $text = $text.Substring(0, $endOfTextOnCurrentLine)
            $remainingText = $fullExtentLine.Substring($endOfTextOnCurrentLine, $fullExtentLine.Length - $endOfTextOnCurrentLine)
            if($remainingText.Length -gt $consoleWidth) {
                $overrunText += ($remainingText | Select-String "(.{1,$consoleWidth})+").Matches.Groups[1].Captures.Value
            } else {
                $overrunText += $remainingText
            }
        }

        $textToRender += @{
            Text = $text
            X = $x
            Y = $y
        }

        # Prepare any parts of this line that extended beyond the width of the terminal
        $overruns = 0
        foreach($overrun in $overrunText) {
            $overruns++
            $textToRender += @{
                Text = $overrun
                X = $GutterSize
                Y = $y + $overruns
            }
        }

        $textToRender | Foreach-Object {
            [Console]::SetCursorPosition($_.X, $TerminalLine + $_.Y)
            [Console]::Write($colorEscapeCode + $_.Text + "$([Char]27)[0m")
        }
    } catch {
        throw $_
    } finally {
        Set-CursorVisible $initialCursorSetting
        [Console]::SetCursorPosition($initialCursorPosition.X, $initialCursorPosition.Y)
    }
}