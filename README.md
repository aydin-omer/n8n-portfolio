# n8n Automation Portfolio

Self-hosted [n8n](https://n8n.io) workflows running on Docker. Each workflow is versioned as JSON in this repository and can be imported into a fresh n8n instance in a few commands.

## Workflows

### CVE Monitor

Checks the [NVD](https://nvd.nist.gov) every hour for newly published HIGH and CRITICAL vulnerabilities and posts a compact summary to a Discord channel.

![Discord alerts](docs/images/discord-alerts.png)

![Workflow](docs/images/workflow.png)

#### How it works

```mermaid
flowchart LR
    A[Schedule<br/>every hour] --> B[Fetch NVD CVEs<br/>last 2 hours]
    B --> C[Parse & Filter<br/>CVSS ≥ 7.0]
    C --> D[Skip Already Seen]
    D --> E[Build Message]
    E --> F[Send to Discord]
```

1. **Fetch NVD CVEs** queries the NVD CVE API 2.0 for everything published in the last two hours.
2. **Parse & Filter** flattens the API response, picks the newest CVSS version available (4.0, then 3.1, then 3.0) and keeps only CVEs scoring 7.0 or higher. Rejected entries and CVEs without a score are dropped.
3. **Skip Already Seen** remembers CVE IDs across executions, so no CVE is reported twice.
4. **Build Message** sorts CVEs by score and packs them into as few Discord messages as possible.
5. **Send to Discord** posts the messages through a webhook.

#### Design decisions

- **Overlapping time window.** The workflow runs every hour but looks back two hours. A delayed run or a brief NVD outage never causes a CVE to be missed. The resulting duplicates are removed by the deduplication step.
- **No secrets in the repository.** The NVD API key and the Discord webhook URL live in n8n's encrypted credential store. The exported workflow JSON only references credentials by name.
- **Flood protection.** Discord rate-limits fast bursts of messages, and dozens of notifications are easy to ignore. CVEs are packed into messages under Discord's 2,000-character limit, and a single run sends at most three messages. Anything beyond that is summarised with a link to the full NVD search.
- **Silent when there is nothing to report.** If no new CVE matches the filter, no message is sent.

#### Known limitations

- NVD often publishes new CVEs before scoring them. Such CVEs are skipped by the filter, so a CVE may never be reported if it receives its score after leaving the two-hour window.
- Only CVSS base scores are considered. Exploitability signals such as CISA KEV or EPSS are not used yet.

#### Configuration

| Setting | Where | Default |
|---|---|---|
| Minimum CVSS score | `MIN_SCORE` in **Parse & Filter** | `7.0` |
| Messages per run | `MAX_MESSAGES` in **Build Message** | `3` |
| Schedule | **Schedule Trigger** | Every hour at minute 5 |

## Getting started

**Requirements:** Docker with Docker Compose, a free [NVD API key](https://nvd.nist.gov/developers/request-an-api-key) and a Discord channel webhook.

```bash
git clone https://github.com/aydin-omer/n8n-portfolio.git
cd n8n-portfolio
cp .env.example .env          # then set N8N_ENCRYPTION_KEY (openssl rand -hex 32)
docker compose up -d
./scripts/import-workflows.sh
```

Then open http://localhost:5679, create the owner account and add two credentials:

| Credential name | Type | Value |
|---|---|---|
| `NVD API Key` | Header Auth | Name `apiKey`, value: your NVD key |
| `Discord CVE Alerts` | Discord Webhook API | Your Discord webhook URL |

Open the **CVE Monitor** workflow, select these credentials in the **Fetch NVD CVEs** and **Send to Discord** nodes, save and activate.

## Repository structure

```
├── docker-compose.yml        # n8n service, pinned version
├── .env.example              # required environment variables
├── scripts/
│   ├── export-workflows.sh   # n8n → ./workflows (strips test data, scans for secrets)
│   └── import-workflows.sh   # ./workflows → n8n
├── workflows/                # one JSON file per workflow
└── docs/images/              # screenshots
```

## Roadmap

- AI-generated plain-language summary for each CVE
- Highlight CVEs listed in the CISA Known Exploited Vulnerabilities catalog
