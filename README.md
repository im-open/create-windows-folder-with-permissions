# Create Windows Folder with Permissions

This action will create a folder, including any nested folders. This will not remove items from the folder.

## Index

- [Inputs](#inputs)
- [Prerequisites](#prerequisites)
- [Example](#example)
- [Contributing](#contributing)
  - [Incrementing the Version](#incrementing-the-version)
- [Code of Conduct](#code-of-conduct)
- [License](#license)

## Inputs

| Parameter                           | Is Required | Description                                            |
| ----------------------------------- | ----------- | ------------------------------------------------------ |
| `server`                            | true        | The name of the target server                          |
| `folder-path`                       | true        | The entire path to the folder                          |
| `read-users`                        | false       | Comma separated list of users for Read access          |
| `write-users`                       | false       | Comma separated list of users for Write access         |
| `modify-users`                      | false       | Comma separated list of users for Modify access        |
| `deployment-service-account-id`     | true        | The service account id used to create the IIS site     |
| `deployment-service-account-secret` | true        | The service account secret used to create the IIS site |

## Prerequisites

The create windows folder with permissions action uses Web Services for Management, [WSMan], and Windows Remote Management, [WinRM], to create remote administrative sessions. Because of this, Windows OS GitHubs Actions Runners, `runs-on: [windows-2019]`, must be used. If the file deployment target is on a local network that is not publicly available, then specialized self hosted runners, `runs-on: [self-hosted, windows-2019]`, will need to be used to broker deployment time access.

Inbound secure WinRm network traffic (TCP port 5986) must be allowed from the GitHub Actions Runners virtual network so that remote sessions can be received.

Prep the remote Windows server to accept WinRM management calls. In general the Windows server needs to have a [WSMan] listener that looks for incoming [WinRM] calls. Firewall exceptions need to be added for the secure WinRM TCP ports, and non-secure firewall rules should be disabled. Here is an example script that would be run on the Windows server:

```powershell
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName <<ip-address|fqdn-host-name>>

Export-Certificate -Cert $Cert -FilePath C:\temp\<<cert-name>>

Enable-PSRemoting -SkipNetworkProfileCheck -Force

# Check for HTTP listeners
dir wsman:\localhost\listener

# If HTTP Listeners exist, remove them
Get-ChildItem WSMan:\Localhost\listener | Where -Property Keys -eq "Transport=HTTP" | Remove-Item -Recurse

# If HTTPs Listeners don't exist, add one
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint –Force

# This allows old WinRm hosts to use port 443
Set-Item WSMan:\localhost\Service\EnableCompatibilityHttpsListener -Value true

# Make sure an HTTPs inbound rule is allowed
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Name "Windows Remote Management (HTTPS-In)" -Profile Any -LocalPort 5986 -Protocol TCP

# For security reasons, you might want to disable the firewall rule for HTTP that *Enable-PSRemoting* added:
Disable-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)"
```

- `ip-address` or `fqdn-host-name` can be used for the `DnsName` property in the certificate creation. It should be the name that the actions runner will use to call to the Windows server.
- `cert-name` can be any name. This file will used to secure the traffic between the actions runner and the Windows server

## Example

```yml
...
env:
  SERVER: web-app.domain.com
  SITE_PATH: 'c:\inetpub\wwwroot'
  READ_USERS: 'svc-website-id,svc-app-id'
  WRITE_USERS: 'svc-app-id'
  MODIFY_USERS: 'svc-app-id'
  DEPLOYMENT_ID: 'deployment_id'
  DEPLOYMENT_SECRET: '${{ secrets.deployment_secret }}'

jobs:
  ...

  deploy:
    runs-on: [windows-2019]
    steps:
      ...

      - name: Create folder and grant permissions
        uses: im-open/create-windows-folder-with-permissions@1.0.0
        with:
          server: ${{ env.SERVER }}
          folder-path: '${{ env.SITE_PATH }}'
          read-users: '${{ env.READ_USERS }}'
          write-users: '${{ env.WRITE_USERS }}'
          modify-users: '${{ env.MODIFY_USERS }}'
          deployment-service-account-id: ${{ env.DEPLOYMENT_ID }}
          deployment-service-account-secret: ${{ secrets.DEPLOYMENT_SECRET }}

      ...
```

## Contributing

When creating new PRs please ensure:

1. For major or minor changes, at least one of the commit messages contains the appropriate `+semver:` keywords listed under [Incrementing the Version](#incrementing-the-version).
2. The `README.md` example has been updated with the new version. See [Incrementing the Version](#incrementing-the-version).
3. The action code does not contain sensitive information.

### Incrementing the Version

This action uses [git-version-lite] to examine commit messages to determine whether to perform a major, minor or patch increment on merge. The following table provides the fragment that should be included in a commit message to active different increment strategies.
| Increment Type | Commit Message Fragment |
| -------------- | ------------------------------------------- |
| major | +semver:breaking |
| major | +semver:major |
| minor | +semver:feature |
| minor | +semver:minor |
| patch | _default increment type, no comment needed_ |

## Code of Conduct

This project has adopted the [im-open's Code of Conduct](https://github.com/im-open/.github/blob/main/CODE_OF_CONDUCT.md).

## License

Copyright &copy; 2022, Extend Health, LLC. Code released under the [MIT license](LICENSE).

[git-version-lite]: https://github.com/im-open/git-version-lite
