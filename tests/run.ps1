param([Parameter(Mandatory=$true)][string]$Luau)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$runtime = (Resolve-Path -LiteralPath $Luau).Path
$mock = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'roblox-mock.luau')
$library = Get-Content -Raw -LiteralPath (Join-Path $repo 'Nocturne(2).lua')
$spec = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'colorbox.spec.luau')
$example = Get-Content -Raw -LiteralPath (Join-Path $repo 'Example(2).lua')
$exampleHarness = @'
local script={Parent={FindFirstChild=function() return {IsA=function() return true end} end}}
local function require() return Library end
local Demo=(function()
'@
$exampleAssertions = @'
end)()
assert(Demo.SelectedTab.Name=="assistance")
assert(Demo.Tabs[3].Name=="miscellaneous")
assert(Demo.Controls.mainnightSky and Demo.Controls.maindaySky)
assert(Demo.Controls.extraColor2:Get()==Color3.fromRGB(103,187,117))
for _,tab in ipairs(Demo.Tabs) do
    tab:Select()
    for _,sub in ipairs(tab.SubTabs or {}) do sub:Select() end
end
Demo:Destroy()
print("PASS: complete example creates, switches every tab/subtab, and destroys")
'@
$combined = $mock + "`nlocal Library=(function()`n" + $library + "`nend)()`n" + $spec + "`n" + $exampleHarness + "`n" + $example + "`n" + $exampleAssertions
$temporary = Join-Path ([System.IO.Path]::GetTempPath()) ('nocturne-test-' + [guid]::NewGuid().ToString('N') + '.luau')
try {
    [System.IO.File]::WriteAllText($temporary, $combined, [System.Text.UTF8Encoding]::new($false))
    & $runtime $temporary
    if ($LASTEXITCODE -ne 0) { throw "Luau tests failed ($LASTEXITCODE)" }
} finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
}
