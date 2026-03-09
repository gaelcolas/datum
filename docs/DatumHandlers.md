# Datum Handlers

Datum Handlers extend what can be stored and resolved from data files. They intercept values at lookup time and transform them — for example, decrypting credentials or evaluating dynamic expressions.

## How Handlers Work

A handler consists of two functions in a PowerShell module:

1. **Filter function** (`Test-<HandlerName>Filter`) — Returns `$true` if the handler should process the value
2. **Action function** (`Invoke-<HandlerName>Action`) — Transforms and returns the new value

When Datum resolves a value, it pipes the value through each registered handler's filter. If the filter matches, the action function is called and the returned value replaces the original.

Handlers are declared in the `DatumHandlers` section of `Datum.yml`:

```yaml
DatumHandlers:
  <ModuleName>::<HandlerName>:
    CommandOptions:
      Param1: Value1
      Param2: Value2
```

This instructs Datum to:

1. Call `<ModuleName>\Test-<HandlerName>Filter` with the value
2. If it returns `$true`, call `<ModuleName>\Invoke-<HandlerName>Action`

## Action Function Parameters

Datum automatically populates parameters of the action function from available variables. The following are typically available:

| Parameter | Description |
|-----------|-------------|
| `$InputObject` | The raw value being processed |
| `$Datum` | The full Datum tree |
| `$Node` | The current node (if in a node context) |
| `$PropertyPath` | The property path being looked up |
| `$File` | A `[System.IO.FileInfo]` object for the data file being processed (see [The `$File` Variable](#the-file-variable)) |
| Any `CommandOptions` key | Values from the Datum.yml configuration |

You do not need to pass these explicitly — Datum matches parameter names to available variables and `CommandOptions` keys.

## Error Handling

By default, handler errors are silently ignored and the raw marker string is returned as-is. This means a failed `[ENC=...]` decryption or broken `[x= ... =]` expression silently returns the unprocessed value, which can be very hard to diagnose.

Set `DatumHandlersThrowOnError` in `Datum.yml` to surface handler failures as terminating errors:

```yaml
DatumHandlersThrowOnError: true
```

**This setting is recommended for all production use.** Without it, a misconfigured certificate or a typo in an expression can go unnoticed until the resulting MOF is applied.

## Built-In Test Handler

Datum includes a test handler that demonstrates the pattern. It matches values like `[TEST=<data>]`.

### Configuration

```yaml
DatumHandlers:
  Datum::TestHandler:
    CommandOptions:
      Password: P@ssw0rd
      Test: test
```

### Filter

The filter uses a regex match:

```powershell
function Test-TestHandlerFilter {
    param($InputObject)
    $InputObject -is [string] -and
    $InputObject -match '^\[TEST=(?<data>[\w\W])*\]$'
}
```

### Action

The action function receives parameters from both the available variables and `CommandOptions`:

```powershell
function Invoke-TestHandlerAction {
    param(
        $Password,  # from CommandOptions
        $Test,       # from CommandOptions
        $Datum       # from Datum context
    )
    # Resolve json depth from Datum.yml (default: 4)
    $jsonDepth = if ($Datum.__Definition.default_json_depth) {
        $Datum.__Definition.default_json_depth
    } else { 4 }

    # Returns diagnostic information about what was received.
    # -WarningAction SilentlyContinue prevents truncation warnings
    # because $PSBoundParameters includes the entire $Datum tree.
    @"
    Action: $handler
    Node: $($Node | Format-List * | Out-String)
    Params:
    $($PSBoundParameters | ConvertTo-Json -Depth $jsonDepth -WarningAction SilentlyContinue)
"@
}
```

### Using the Test Handler for Redirections

You can modify the test handler to follow references to other Datum paths:

```powershell
function Invoke-TestHandlerAction {
    param(
        $Datum,
        $InputObject
    )

    $datumLink = [regex]::Matches(
        $InputObject,
        '^\[TEST=(?<data>[\w\W]*)\]$'
    )[0].groups['data'].value -split '\\'

    [scriptblock]::Create(
        "`$Datum.$($datumLink -join '.')"
    ).Invoke()
}
```

When a value is `'[TEST=Roles\Role1\Shared1\DestinationPath]'`, this resolves and returns `$Datum.Roles.Role1.Shared1.DestinationPath`.

## Datum.ProtectedData — Encrypted Credentials

The [Datum.ProtectedData](https://www.powershellgallery.com/packages/Datum.ProtectedData) module stores encrypted `[PSCredential]` objects in YAML files.

### Installation

```powershell
Install-Module -Name Datum.ProtectedData -Scope CurrentUser
```

This also installs the [ProtectedData](https://www.powershellgallery.com/packages/ProtectedData) module by Dave Wyatt, which provides the underlying encryption engine.

### Configuration

The handler is registered in `Datum.yml`. Use **one** of the two parameter sets:

```yaml
# PRODUCTION — decrypt using a certificate
DatumHandlers:
  Datum.ProtectedData::ProtectedDatum:
    CommandOptions:
      Certificate: 0A1B2C3D4E5F...   # thumbprint, cert file path, or cert: provider path

# TESTING ONLY — decrypt using a plain-text password
DatumHandlers:
  Datum.ProtectedData::ProtectedDatum:
    CommandOptions:
      PlainTextPassword: P@ssw0rd
```

> **Warning:** `PlainTextPassword` is intended for development and testing only. In production, always use a certificate whose private key is available on the build/compilation machine.

### Encrypting Data with `Protect-Datum`

Before an encrypted value can appear in a data file, you must create the encrypted blob with the `Protect-Datum` helper function:

```powershell
# Using a certificate (production)
$credential = Get-Credential
$blob = Protect-Datum -InputObject $credential -Certificate '0A1B2C3D4E5F...'
# → '[ENC=PE9ianM...long base64...=]'

# Using a password (testing)
$securePassword = ConvertTo-SecureString -AsPlainText -Force 'P@ssw0rd'
$blob = Protect-Datum -InputObject $credential -Password $securePassword
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `InputObject` | `[PSObject]` | The object to encrypt (credential, secure string, or any serialisable object) |
| `Certificate` | `[string]` | Certificate thumbprint, file path, or cert provider path |
| `Password` | `[SecureString]` | Encryption password (testing only) |
| `MaxLineLength` | `[int]` | Line-wrap width for the base64 block (default: 100) |
| `Header` / `Footer` | `[string]` | Encapsulation markers (defaults: `[ENC=` / `]`) |
| `NoEncapsulation` | `[switch]` | Emit the raw base64 without header/footer |

Paste the returned string into your YAML data file.

### Decrypting Data Manually with `Unprotect-Datum`

For debugging or scripting outside the handler pipeline, use `Unprotect-Datum`:

```powershell
$decrypted = '[ENC=PE9ianM...]' | Unprotect-Datum -Certificate '0A1B2C3D4E5F...'
```

`Unprotect-Datum` accepts the same `Certificate` / `Password` parameter sets as `Protect-Datum`.

### How Decryption Works at Lookup Time

Encrypted values in data files are prefixed with `[ENC=`:

```yaml
# In a data file
AdminCredential: '[ENC=PE9ianM... (encrypted blob) ...=]'
```

When Datum resolves this value, the `ProtectedDatum` handler:

1. Detects the `[ENC=` prefix via its filter (regex `^\[ENC=[\w\W]*\]$`)
2. Strips the header/footer and decodes the base64 payload
3. Decrypts the blob using the configured certificate or password
4. Returns the original object (typically a `[PSCredential]`)

Decrypted values are **cached in memory** for the duration of the session, so repeated lookups of the same encrypted blob do not re-run the decryption.

This allows credentials to be stored securely in version control while being transparently decrypted at lookup time.

### Real-World Example

In the [DscWorkshop](https://github.com/dsccommunity/DscWorkshop) project, encrypted credentials are stored in a shared `Global/Domain.yml` file:

```yaml
# Global/Domain.yml
DomainFqdn: contoso.com
DomainDn: DC=contoso,DC=com
DomainAdminCredentials: '[ENC=PE9ianM...]'
DomainJoinCredentials: '[ENC=PE9ianM...]'
```

Other layers reference these credentials via InvokeCommand expressions:

```yaml
# Roles/DomainController.yml
DomainJoinCredential: '[x={ $Datum.Global.Domain.DomainJoinCredentials }=]'
```

This keeps credentials in one place and decrypts them transparently during RSOP compilation.

## Datum.InvokeCommand — Dynamic Expressions

The [Datum.InvokeCommand](https://www.powershellgallery.com/packages/Datum.InvokeCommand) module enables PowerShell expressions to be evaluated dynamically at lookup time.

### Installation

```powershell
Install-Module -Name Datum.InvokeCommand -Scope CurrentUser
```

### Configuration

```yaml
DatumHandlers:
  Datum.InvokeCommand::InvokeCommand:
    SkipDuringLoad: true
```

> **Important:** The `SkipDuringLoad: true` setting ensures expressions are only evaluated during lookup, not when the data file is first loaded into memory.

### Usage

Wrap PowerShell expressions in `[x= ... =]`. The handler supports two expression types:

**Scriptblocks** — wrapped in curly braces, executed via `& (& { ... })`:

```yaml
CurrentDate: '[x= { Get-Date -Format "yyyy-MM-dd" } =]'
ComputerName: '[x= { $env:COMPUTERNAME } =]'
DynamicPath: '[x= { Join-Path $env:ProgramFiles "MyApp" } =]'
```

**Expandable strings** — wrapped in double quotes, expanded via `$ExecutionContext.InvokeCommand.ExpandString()`:

```yaml
Greeting: '[x= "Hello from $($Node.Name)" =]'
LogPath: '[x= "C:\Logs\$($Node.Environment)\$($Node.Name)" =]'
```

Scriptblocks are the most common form and can contain any PowerShell code. Expandable strings are lighter-weight and useful for simple variable interpolation.

When resolved, the expression is evaluated and the result replaces the marker.

### The `$File` Variable

Inside `[x= ... =]` expressions, the `$File` variable is a `[System.IO.FileInfo]` object representing the data file currently being processed. This makes data files **location-aware** — they can derive values from their own file name or directory without hard-coding.

| Expression | Returns | Example |
|-----------|---------|--------|
| `$File.BaseName` | File name without extension | `DSCWeb01` |
| `$File.Name` | File name with extension | `DSCWeb01.yml` |
| `$File.Directory.BaseName` | Parent directory name | `Dev` |
| `$File.Directory.FullName` | Full parent directory path | `C:\ConfigData\AllNodes\Dev` |

#### Practical Examples

Derive a node's `NodeName` from its file name:

```yaml
# AllNodes/Dev/DSCWeb01.yml
NodeName: '[x={ $Node.Name }=]'             # → DSCWeb01
Environment: '[x={ $File.Directory.BaseName }=]'  # → Dev
```

Use the file's base name in generated paths:

```yaml
# Locations/Frankfurt.yml
FileSystemObjects:
  Items:
    - DestinationPath: '[x= "C:\Test\$($File.BaseName)" =]'  # → C:\Test\Frankfurt
```

> **Note:** `$Node.Name` is set automatically by the FileProvider from the data file's base name. This is distinct from `$Node.NodeName`, which is a property typically set *inside* the data file. In practice, `$Node.Name` is available first and is commonly used to bootstrap `NodeName`.

### Cross-Datum References

Expressions can reach into any part of the Datum tree via the `$Datum` variable. This is useful for referencing shared data stored in a [Global data store](DatumYml.md#global-data-stores):

```yaml
# Roles/DomainController.yml
DomainName: '[x={ $Datum.Global.Domain.DomainFqdn }=]'
DomainCredential: '[x={ $Datum.Global.Domain.DomainJoinCredentials }=]'
```

You can also reference baselines or other layers:

```yaml
NodeVersion: '[x={ $Datum.Baselines.DscLcm.DscTagging.Version }=]'
```

### Source Tracking with `Get-DatumSourceFile`

The `Get-DatumSourceFile` function can be called inside expressions to record which file contributed data. This is used by the DscTagging pattern to track layer provenance:

```yaml
# Baselines/DscLcm.yml
DscTagging:
  Layers:
    - '[x={ Get-DatumSourceFile -Path $File }=]'
```

As each layer file adds its own entry via the `Unique` merge strategy, the final RSOP contains a complete list of which files contributed to the node.

### Nested Expression Resolution

If an expression's result itself contains an `[x= ... =]` marker, the handler recursively resolves it. This allows chained references:

```yaml
# Global/Paths.yml
BasePath: 'C:\App'

# Roles/WebServer.yml
AppPath: '[x= "$($Datum.Global.Paths.BasePath)\Web" =]'

# AllNodes/Dev/SRV01.yml
LogPath: '[x={ "$($Datum.Roles.WebServer.AppPath)\Logs" }=]'
```

The handler keeps resolving until no more markers remain in the result.

### Self-Referencing Loop Prevention

If an expression calls `Get-DatumRsop` and that call is already on the call stack (i.e. the expression was triggered *from* `Get-DatumRsop`), the handler returns the raw expression string instead of recursing infinitely. This makes it safe to use `Get-DatumRsop` inside expressions for cross-node lookups without risking an infinite loop.

### Importing External Data

Because expressions are arbitrary PowerShell, they can pull data from external sources such as CSV files, databases, or APIs:

```yaml
# Import IP addresses from a CSV file
NetworkConfig:
  IpAddress: '[x={ ($importedCsv | Where-Object ComputerName -eq $Node.Name).IpAddress }=]'
```

In the [DscWorkshop](https://github.com/dsccommunity/DscWorkshop) reference implementation, a CSV file is imported during the build and made available as a variable that expressions can query.

### Known Limitations

- Expressions are evaluated in the current PowerShell session context
- Complex expressions with nested quotes may need careful escaping
- Error handling within expressions is the responsibility of the expression author (see [Error Handling](#error-handling))
- Literal strings (wrapped in single quotes `'...'`) are **not** expanded — use scriptblocks or double-quoted strings

## Building Custom Handlers

### Step 1: Create a Module

Create a PowerShell module with two exported functions:

```powershell
# MyDatumHandler.psm1

function Test-MyHandlerFilter {
    param($InputObject)

    # Return $true if this handler should process the value
    $InputObject -is [string] -and
    $InputObject -match '^\[MYPREFIX=.*\]$'
}

function Invoke-MyHandlerAction {
    param(
        $InputObject,
        $Datum,
        $Node,
        $MyConfigParam  # from CommandOptions
    )

    # Extract the data from the marker
    $data = [regex]::Match($InputObject, '^\[MYPREFIX=(?<data>.*)\]$').Groups['data'].Value

    # Transform and return the value
    # ... your transformation logic here ...
    return $transformedValue
}
```

### Step 2: Make the Module Available

Ensure the module is in a path listed in `$env:PSModulePath` or install it from a repository.

### Step 3: Register in Datum.yml

```yaml
DatumHandlers:
  MyDatumHandler::MyHandler:
    CommandOptions:
      MyConfigParam: SomeValue
```

### Naming Convention

The `DatumHandlers` key format is `<ModuleName>::<HandlerName>`:

- Datum calls `<ModuleName>\Test-<HandlerName>Filter` for the filter
- Datum calls `<ModuleName>\Invoke-<HandlerName>Action` for the action

### Tips

- Keep filter functions fast — they run on every resolved value
- Use specific prefixes (e.g. `[ENC=`, `[x=`) to avoid false matches
- Test handlers thoroughly — a handler bug affects all data resolution
- The `SkipDuringLoad` option (when supported) defers handler execution to lookup time

## See Also

- [Datum.yml Reference](DatumYml.md) — Full configuration file reference
- [README - Datum Handlers](../README.md#datum-handlers)
- [Datum.ProtectedData on PowerShell Gallery](https://www.powershellgallery.com/packages/Datum.ProtectedData) — [Source on GitHub](https://github.com/gaelcolas/Datum.ProtectedData)
- [Datum.InvokeCommand on PowerShell Gallery](https://www.powershellgallery.com/packages/Datum.InvokeCommand) — [Source on GitHub](https://github.com/raandree/Datum.InvokeCommand)
