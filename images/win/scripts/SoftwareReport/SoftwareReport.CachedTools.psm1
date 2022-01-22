function Get-NodeMarkdown
{
    $Name = "Node"
    $ToolInstances = Get-CachedToolInstances -Name $Name
    $Content = $ToolInstances | New-MDTable -Columns ([ordered]@{Version = "left"; Architecture = "left"})

    return Build-MarkdownElement -Head $Name -Content $Content
}

function Get-PythonMarkdown
{
    $Name = "Python"
    $ToolInstances = Get-CachedToolInstances -Name $Name -VersionCommand "--version"
    $Content = $ToolInstances | New-MDTable -Columns ([ordered]@{Version = "left"; Architecture = "left"})

    return Build-MarkdownElement -Head $Name -Content $Content
}

function Build-CachedToolsMarkdown
{
    $markdown = ""
    $markdown += Get-NodeMarkdown
    $markdown += Get-PythonMarkdown

    return $markdown
}
