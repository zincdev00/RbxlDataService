$PrevPath = (Get-Location).Path
$RootPath = $PSScriptRoot
Set-Location -path $RootPath


class Source {
	[string]$Origin
	[string]$Target

	Source() { $this.Init(@{}) }
	Source([hashtable]$Properties) { $this.Init($Properties) }
	Source([string]$Origin, [string]$Target) {
		$this.Init(@{
			Origin = $Origin;
			Target = $Target;
		})
	}
	[void] Init([hashtable]$Properties) {
		foreach($Property in $Properties.Keys) {
			$this.$Property = $Properties.$Property
		}
	}
}
class Dependency {
	[string]$Name
	[string]$Path
	[string]$Task
	[Source[]]$Sources

	Dependency() { $this.Init(@{}) }
	Dependency([hashtable]$Properties) { $this.Init($Properties) }
	Dependency([string]$Name, [string]$Path, [string]$Task, [Source[]]$Sources) {
		$this.Init(@{
			Name = $Name;
			Path = $Path;
			Task = $Task;
			Sources = $Sources;
		})
	}
	[void] Init([hashtable]$Properties) {
		foreach($Property in $Properties.Keys) {
			$this.$Property = $Properties.$Property
		}
	}

	[void] Build() {
		Set-Location -path $this.Path
		Write-Host "Building dependency $($this.Name)"
		& ./$($this.Task)
		foreach($Source in $this.Sources) {
			Write-Host "\tImporting $($Source.Origin)"
			Copy-Item -path "$($Source.Origin)" -destination "$($Source.Target)" -force
		}
	}
}
class Component {
	[string]$Name
	[string]$Path
	[string]$File

	Component() { $this.Init(@{}) }
	Component([hashtable]$Properties) { $this.Init($Properties) }
	Component([string]$Name, [string]$Path, [string]$File) {
		$this.Init(@{
			Name = $Name;
			Path = $Path;
			File = $File;
		})
	}
	[void] Init([hashtable]$Properties) {
		foreach($Property in $Properties.Keys) {
			$this.$Property = $Properties.$Property
		}
	}

	[void] Build() {
		Set-Location -path $this.Path
		Write-Host "Compiling module $($this.Name)"
		& rojo build "$($this.Name)" -o "$($this.File)"
	}
}


$Project = @{
	Name = "DataService";
	Root = $RootPath;
}
foreach($Element in @(
	[Component]::new(@{
		Name = "main";
		Path = "$($Project.Root)";
		File = "build/$($Project.Name).rbxm";
	});
)) {
	$Element.Build()
}


Set-Location -path $PrevPath