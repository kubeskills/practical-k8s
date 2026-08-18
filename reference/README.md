# Core Reference Pack

Printable cheat sheets for use throughout the course. Content is adapted from official Kubernetes documentation (CC BY 4.0) — see attribution in each source `.md` file.

| Reference | Markdown source | PDF |
|---|---|---|
| kubectl quick reference — commands and flags for pods, deployments, services, debugging, and common patterns | [kubectl-quick-reference.md](kubectl-quick-reference.md) | [kubectl-quick-reference.pdf](kubectl-quick-reference.pdf) |
| Kubernetes architecture & components cheat sheet — control plane, node components, addons | [kubernetes-architecture-cheatsheet.md](kubernetes-architecture-cheatsheet.md) | [kubernetes-architecture-cheatsheet.pdf](kubernetes-architecture-cheatsheet.pdf) |
| CKA exam objectives → course map — maps every official CKA curriculum objective to the lab, slide, or manifest that covers it | [cka-exam-objectives-map.md](cka-exam-objectives-map.md) | [cka-exam-objectives-map.pdf](cka-exam-objectives-map.pdf) |

## Official Tutorials & Interactive Labs

No install required — use these to practice outside of class or between lab environments.

| Resource | Description |
|---|---|
| [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/) (official) | Interactive, browser-based tutorials covering Pods, Deployments, Services, and more |
| [Play with Kubernetes](https://labs.play-with-k8s.com/) | Free, ephemeral clusters in the browser for safe experimentation without local setup |
| [Killercoda Kubernetes scenarios](https://killercoda.com/kubernetes) | Guided, browser-terminal labs for networking, troubleshooting, and core objects |

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
