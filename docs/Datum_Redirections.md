# Datum Redirections

Natively, Datum does not support redirections **YET**.
That said, you can implement it quite easily thanks to the (under documented) feature of the Datum Handlers.

## The Built-In Test Handler & Principle
In some examples, the `Datum.yml` contains the following block:
```yaml

DatumHandlers:
  Datum::TestHandler: # Datum\Test-TestHandlerFilter & Invoke-TestHandlerAction
    CommandOptions:
      Password: P@ssw0rd
      Test: test
```

It instructs Datum to pipe any Datum to the Filter of the Test handler (The fully qualified name of the function is built from the `Datum::TestHandler`, to call `$DatumValue | Datum\Test-TestHandlerFilter`).
If the result of this test is `$true`, then the Test Handler Action is triggered (`Datum\Invoke-TestHandlerAction`), and the returned value will replace the Datum value for the key.

As an example, a company using Datum to manage their infrastructure data with DSC has created a **SecretServer** Datum Handler, to retrieve Credentials Objects from their _Thycotic SecretServer_.

## Filter 

The Test filter do a simple matches for `$InputObject -is [string] -and $InputObject -match "^\[TEST=(?<data>[\w\W])*\]$"`.

When the Data is like `Test: '[TEST=Roles\Role1\Shared1\DestinationPath]'` the Handler Action will be invoked.

## Action parameters

Datum will automatically try to fill the parameters defined in the Action function from the available variables.

By default (in DSC at least), you probably have the following variables already available:
```PowerShell
$Datum
$InputObject
$Node
$PropertyPath
... # to be continued
```

Also, the variable from the `CommandOptions:` in `Datum.yml` are available, in this example above: the `$password` will be `"P@ssw0rd"` and `$Test` will be `'test'`.

The test Action is only to return a blob of Data to show the concept:

```PowerShell
function Invoke-TestHandlerAction {
    Param(
        $Password,
        $test,
        $Datum
    )
@"
    Action: $handler
    Node: $($Node|FL *|Out-String)
    Params: 
$($PSBoundParameters | Convertto-Json)
"@
}
```

Now you can change what you've learned to modify it or create your own, and follow a redirection.

## Changing the Test Handler's action to follow a redirection

You can change the Invoke-TestHandlerAction function to follow an absolute path in in the Datum object.
```PowerShell
# Invoke-TestHandlerAction.ps1
function Invoke-TestHandlerAction {
    Param(
        $Datum,
        $InputObject
    )

    $datumLink = [regex]::Matches($InputObject,"^\[TEST=(?<data>[\w\W]*)\]$")[0].groups['data'].value -split '\\'
    [scriptblock]::Create("`$Datum.$($datumLink -join '.')").Invoke()
}
```

Now when the Datum - as in AllNodes\DEV\SRV01.yml - has a property `test` like so: `Test: '[TEST=Roles\Role1\Shared1\DestinationPath]'`, it will be returned the value available in `$Datum.Roles.Role1.Shared1.DestinationPath`, in this case: the `Test` property will be `C:\MyRoleParam.txt`.


## Doing a nested lookup

Should you do a nested lookup, you'd probably have to do something like (not tested recently):
> `Lookup -PropertyPath $datumLink -Node $Node -DefaultValue @{} -DatumTree $datum`

The problem with this one is that if you have recursive loops, it is not handled, and your PowerShell session will likely crash.

Contributors and myself will eventually add this feature natively, let us know if you need it.
Same with variable interpolation where you can add and concatenate Datum values such as: `<lookup username>@<lookup domain>`.

## Building your own Handler

In a module named _**YourModuleName**_ you should create two functions called:
> Test-__**YourHandlerName**__Filter

> Invoke-__**YourHandlerName**__Action

Make it available in your PowerShell session (i.e. Module autoload and in `$Env:PSModulePath`), and declare it in the `Datum.yml` configuration (always reload your `$Datum` when changing `Datum.yml`):

```yaml

YourModuleName:
  YourModuleName::YourHandlerName: # Datum\Test-TestHandlerFilter & Invoke-TestHandlerAction
    CommandOptions:
        YourOptionalParam1: YourOptionalParam1Value
```
