# gha-mastery - 3-day GitHub Actions course repo

Two small apps from a futures-trading desk, plus the Ansible and Azure pieces to ship them.

| Folder | What it is | Built on |
|---|---|---|
| `java-api/` | Contract Specs API - tick size / tick value per futures symbol (JDK HTTP server, JUnit 5) | Maven, Java 25 |
| `winforms-app/` | Position Sizer - "how many contracts can I trade for $X risk?" (WinForms + xUnit) | .NET 10, Windows |
| `ansible/` | `java_api` role (systemd service), Windows stretch playbook | ansible-core |
| `infra/` | Azure CLI scripts: setup (free-tier VM, storage, OIDC), stretch Windows VM, teardown | Azure CLI |
| `solutions/.github/` | Finished workflows and composite action for every lab. Try first, peek later. | GitHub Actions |

## How to use
1. Create an **empty public repo** named `gha-mastery` on GitHub (public = free Actions minutes + environment approvals on a Free plan).
2. Copy everything *except* `solutions/` into it and push.
3. Follow the course page day by day. Each lab tells you which file to create under `.github/`.

## Run locally
```bash
cd java-api && mvn verify && java -jar target/contract-specs-api.jar   # http://localhost:8080/health
cd winforms-app && dotnet test && dotnet run --project src/PositionSizer.App   # Windows only for the UI
```