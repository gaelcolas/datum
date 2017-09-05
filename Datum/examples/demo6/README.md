# Solution

This demo shows the Use of the Lookup function (also a ScriptToProcess, because Scope), that simplifies the Datum call to Resolve-Datum, and cater for Default value, Error when no value is found.

It will also allow for a second Datum lookup to a DSC Composite Resource's Configuration (Server Side), when there is no result returned from the Global Configuration Data and No Default Specified.

```
C:\SRC\DATUM\DATUM\EXAMPLES\DEMO6
│   datum.yml
│   demo6.ps1
│   LoadConfigData.ps1
│   README.md
│
├───ConfigData
│   ├───Environments
│   │   ├───DEV
│   │   │       SRV01.yml
│   │   │
│   │   └───PROD
│   └───SiteData
│           All.psd1
│           Site01.psd1
│           Site02.psd1
│
├───Configurations
│   └───PLATFORM
│       │   PLATFORM.psd1
│       │
│       └───DscResources
│           ├───Base
│           │   │   Config1.psd1
│           │   │   Config1.schema.psm1
│           │   │
│           │   ├───ConfigData
│           │   │   └───common
│           │   └───Validation
│           └───Config1
│               │   Config1.psd1
│               │   Config1.schema.psm1
│               │
│               ├───ConfigData
│               │   │   Datum.yml
│               │   │
│               │   └───common
│               │           Config1.yml
│               │
│               └───Validation
└───Roles
        MyRole.yml
```