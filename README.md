# 🌈 PwshSyntaxHighlight

[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PwshSyntaxHighlight)](https://www.powershellgallery.com/packages/PwshSyntaxHighlight)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PwshSyntaxHighlight)](https://www.powershellgallery.com/packages/PwshSyntaxHighlight)
[![GitHub license](https://img.shields.io/github/license/ShaunLawrie/PwshSyntaxHighlight)](https://github.com/ShaunLawrie/PwshSyntaxHighlight/blob/main/LICENSE)

PwshSyntaxHighlight is a simple syntax highlighter for rendering PowerShell code blocks inside the terminal. This is a standalone version of the codeblock renderer I built for [PowerShell AI](https://github.com/dfinke/PowerShellAI).

![image](https://github.com/ShaunLawrie/PwshSyntaxHighlight/assets/13159458/9b3f4a2d-79c0-4446-aeea-6553b830a819)

# Install

```pwsh
Install-Module PwshSyntaxHighlight -Scope CurrentUser
```

# Usage

## 1. Generate Sample Code

Create some sample code to use in the examples below using a multi-line string variable like this.
```pwsh
$sampleCode = @'
function Test-ThisThingOut {
    param (
        [string] $Parameter
    )
    $message = "$Parameter is the parameter"
    Write-Host "Hello PwshSyntaxHighlight! $message"
}
'@
```

## 2. Render Code Blocks

Pass the code as the `-Text` parameter to render a code block, use `-SyntaxHighlight` to enable highlighting and `-ShowLineNumbers` to show a gutter down the left containing the code line numbers.
```pwsh
Write-CodeBlock -Text $sampleCode -SyntaxHighlight -ShowLineNumbers
```
![Example of syntax highlighting](/PwshSyntaxHighlight/private/PwshSyntaxHighlightExample1.png)

## 3. Use Themes

There are only two basic themes available at the moment, GitHub (default) and Matrix, if you're interested you could open a PR for more.
```pwsh
Write-CodeBlock -Text $sampleCode -SyntaxHighlight -ShowLineNumbers -Theme Matrix
```
![Example of syntax highlighting](/PwshSyntaxHighlight/private/PwshSyntaxHighlightExample4.png)

## 4. Highlight Specific Lines

```pwsh
# Provide a list of lines to highlight to draw attention to them with -HighlightLines
Write-CodeBlock $sampleCode -HighlightLines 2, 3, 4 -ShowLineNumbers
```
![Example of syntax highlighting](/PwshSyntaxHighlight/private/PwshSyntaxHighlightExample2.png)

## 5. Highlight Extents

By passing a collection of Extents into `Write-CodeBlock` you can have the extents highlighted in the rendered code. This is how errors are highlighted in the [PowerShell AI Function Builder demo on YouTube](https://youtu.be/MbHTrVdTJXE).  
Parsing PowerShell code with the built-in Abstract Syntax Tree is too much for me to document here but you can check out the awesome details available at [powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree](https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree) if you're interested.  

```pwsh
# Create a script block from the sample code
$scriptBlock = [ScriptBlock]::Create($sampleCode)

# Get a list of items from the abstract syntax tree that are double quoted strings
$astItems = $scriptBlock.Ast.FindAll({$args[0].StringConstantType -eq "DoubleQuoted"}, $true)

# Get the extents for all of those double quoted strings
$extents = $astItems | Select-Object -ExpandProperty Extent

$sampleCode | Write-CodeBlock -HighlightExtents $extents -ShowLineNumbers
```
![Example of syntax highlighting](/PwshSyntaxHighlight/private/PwshSyntaxHighlightExample3.png)
