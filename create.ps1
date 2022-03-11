function SaveProject {
    [CmdletBinding()]
    param(
        [xml]$doc,
        [string]$path
    )

    $settings = New-Object -TypeName 'System.Xml.XmlWriterSettings' -Property @{Indent=$true; OmitXmlDeclaration=$true}
    $writer = [System.Xml.XmlWriter]::Create($path, $settings)

    try
    {
        $doc.Save($writer)
    }
    finally
    {
        $writer.Dispose();
    }
}

function AddProjectReference {
    [CmdletBinding()]
    param(
        [xml]$doc,
        [string]$path
    )

    $projReference = $doc.CreateElement('ProjectReference')
    $projReference.SetAttribute('Include', $path)

    $doc.SelectSingleNode('Project//ItemGroup').AppendChild($projReference)
}

function AddPackageReference {
    param (
        [xml]$doc,
        [string]$package,
        [string]$version,
        [string]$noWarn
    )

    $packageReference = $doc.CreateElement('PackageReference')
    $packageReference.SetAttribute('Include', $package)
    $packageReference.SetAttribute('Version', $version)

    $noWarnElem = $doc.CreateElement('NoWarn')
    $noWarnElem.InnerText = $noWarn

    $packageReference.AppendChild($noWarnElem)

    $doc.SelectSingleNode('Project//ItemGroup').AppendChild($packageReference)
}

mkdir 'src'

$n = 30

For ($i = 1; $i -le $n; $i++) {
    mkdir "src\ClassLibrary${i}"

    [xml]$doc = Get-Content 'template.xml'

    for ($j = 1; $j -lt $i; $j++) {
        AddProjectReference $doc "..\ClassLibrary${j}\ClassLibrary${j}.csproj"
    }

    SaveProject $doc "src\ClassLibrary${i}\ClassLibrary${i}.csproj"
}

[xml]$root = Get-Content 'template.xml'
[xml]$rootLeft = Get-Content 'template.xml'
[xml]$rootRight = Get-Content 'template.xml'

AddProjectReference $root "..\RootLeft\RootLeft.csproj"
AddProjectReference $root "..\RootRight\RootRight.csproj"

AddProjectReference $rootLeft "..\ClassLibrary${n}\ClassLibrary${n}.csproj"
AddPackageReference $rootLeft 'Microsoft.EntityFrameworkCore' '6.0.0' 'NU1000'
AddPackageReference $rootLeft 'Microsoft.Extensions.DependencyInjection' '5.0.2' ''

AddProjectReference $rootRight "..\ClassLibrary${n}\ClassLibrary${n}.csproj"

mkdir "src\Root"
mkdir "src\RootLeft"
mkdir "src\RootRight"

SaveProject $root "src\Root\Root.csproj"
SaveProject $rootLeft "src\RootLeft\RootLeft.csproj"
SaveProject $rootRight "src\RootRight\RootRight.csproj"

dotnet new sln --output src --name LotsOfDependencies
dotnet sln src\LotsOfDependencies.sln add (Get-ChildItem -r **/*.csproj)
