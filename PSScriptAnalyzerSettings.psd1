@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # This is a console tool: Write-Host is the output, and the text is not meant to be piped.
        'PSAvoidUsingWriteHost'
    )
}
