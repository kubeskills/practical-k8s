# Core Reference Pack

Printable cheat sheets for use throughout the course. Content is adapted from official Kubernetes documentation (CC BY 4.0) — see attribution in each source `.md` file.

| Reference | Markdown source | PDF |
|---|---|---|
| kubectl quick reference — commands and flags for pods, deployments, services, debugging, and common patterns | [kubectl-quick-reference.md](kubectl-quick-reference.md) | [kubectl-quick-reference.pdf](kubectl-quick-reference.pdf) |
| Kubernetes architecture & components cheat sheet — control plane, node components, addons | [kubernetes-architecture-cheatsheet.md](kubernetes-architecture-cheatsheet.md) | [kubernetes-architecture-cheatsheet.pdf](kubernetes-architecture-cheatsheet.pdf) |

## Official upstream sources

- [kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/) — kubernetes.io
- [Kubernetes Cluster Components](https://kubernetes.io/docs/concepts/overview/components/) — kubernetes.io
- [Kubernetes Cluster Architecture](https://kubernetes.io/docs/concepts/architecture/) — kubernetes.io

## Regenerating the PDFs

After editing a `.md` file in this directory, regenerate its PDF:

```bash
npm run reference:pdf
```

This renders every `.md` file in `reference/` to a matching `.pdf` using [marked](https://github.com/markedjs/marked) + Playwright (see `scripts/md-to-pdf.mjs`).
