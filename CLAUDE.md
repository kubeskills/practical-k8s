# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

4-day hands-on Kubernetes training course (NobleProg). This is **training content**, not production infrastructure — manifests are teaching tools with complexity increasing progressively across days.

## Commands

```bash
# Install dependencies (one-time)
npm install

# Start slide server for a specific day (opens http://localhost:3030)
npm run day1    # day2, day3, day4

# Build static HTML for a day
npm run build:day1    # build:day2, build:day3, build:day4

# Export slides to PDF (requires playwright-chromium)
npm run export:day1   # export:day2, export:day3, export:day4
```

There are no tests, linters, or CI/CD pipelines in this repo.

## Architecture

- **Slides**: [Slidev](https://sli.dev) markdown presentations in `dayN/slides.md` (~6,300 lines total across 4 days)
- **Labs**: Hands-on exercises in `dayN/labs/labN-<topic>.md` (20+ labs total)
- **Manifests**: YAML resource definitions in `dayN/manifests/` (~100 files). Day 2 also has duplicates in `day2/assets/`
- **kubectl reference**: `dayN/kubectl-commands.sh` files (days 2-4) contain all kubectl commands from slides
- **Slide assets**: Images/diagrams in `dayN/public/`
- **examples/**: Template directory with subdirs (deployments, monitoring, rbac, services, storage) — currently empty/reserved

### Day progression

| Day | Topic | Focus |
|-----|-------|-------|
| 1 | Foundations & Cluster Setup | Containers, architecture, kubeadm, CNI |
| 2 | Core Concepts & Workloads | Deployments, ConfigMaps, Secrets, probes, HPA |
| 3 | Networking, Scheduling & Storage | Services, Ingress, Gateway API, PV/PVC, taints/tolerations |
| 4 | Security, Monitoring & Troubleshooting | RBAC, Pod Security, Prometheus/Grafana, etcd backup, upgrades |

## Manifest Conventions

Training manifests intentionally start simple (Day 1) and layer in best practices progressively. When **adding new manifests** or editing existing ones for instructor/reference use, follow these rules:

- Pin image tags to specific versions (never `latest`)
- Set `resources.requests` and `resources.limits`
- Include a `NetworkPolicy` for new workloads
- Add `securityContext` with `runAsNonRoot: true` where appropriate

Early-day manifests may omit these for pedagogical simplicity — that's intentional for student exercises.

## Slide Authoring

Slides use Slidev markdown syntax. Key patterns:
- `---` separates slides
- Frontmatter on each slide controls layout (`layout: center`, `layout: two-cols`, etc.)
- Speaker notes go below `<!--` comment blocks
- Images referenced from `dayN/public/` directory
- Code blocks with `{monaco}` enable live editing in presentation
