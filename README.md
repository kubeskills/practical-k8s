# Practical Kubernetes Administration and Troubleshooting

**Instructor:** Chad M. Crowell  
**Dates:** February 17-20, 2026  
**Location:** Austin, TX (In-person)  

---

## 🎯 Training Overview

This 4-day hands-on training covers practical Kubernetes administration from cluster setup through advanced troubleshooting. Each day includes guided labs in cloud-based environments.

## 📚 Daily Schedule

### [Day 1: Foundations and Cluster Setup](day1/) - Feb 17
- Containers vs Virtual Machines
- Kubernetes Architecture
- Installing and Configuring Kubernetes
- **Labs:** Cluster provisioning, kubeadm setup, CNI deployment

### [Day 2: Core Concepts and Workload Management](day2/) - Feb 18
- Managing Kubernetes Objects
- Command-Line Tools and Workflows
- **Labs:** Deployments, ConfigMaps, Secrets, Health Checks

### [Day 3: Networking, Scheduling, and Storage](day3/) - Feb 19
- Kubernetes Networking
- Scheduling and Workload Distribution
- Persistent Storage
- Ingress and Gateway API
- **Labs:** Services, Ingress, Storage configuration, LoadBalancers

### [Day 4: Security, Monitoring, and Troubleshooting](day4/) - Feb 20
- Security Essentials (RBAC, Network Policies)
- Monitoring and Observability
- Troubleshooting and Cluster Operations
- **Labs:** RBAC configuration, monitoring setup, cluster upgrades

---

## 🚀 Getting Started

### Prerequisites
- Basic Linux command-line experience
- Understanding of containerization concepts
- Laptop with SSH client

### Clone This Repository
```bash
git clone https://github.com/chadmcrowell/k8s-training-feb-2026.git
cd k8s-training-feb-2026
```

---

## 🖥️ Presenting the Slides

The slides are built with [Slidev](https://sli.dev). Each day has its own slide deck in `dayN/slides.md`.

### Setup (one time)

```bash
npm install
```

### Start the slide server

```bash
npm run day1    # or day2, day3, day4
```

This opens the slides at **http://localhost:3030** in your default browser.

### Presenting on the big screen

1. **Connect** your laptop to the projector/TV (HDMI or USB-C adapter)
2. **Mirror or extend** your display (System Settings > Displays)
3. Run `npm run day1` — the slides open in your browser
4. Press **`f`** in the browser to go **fullscreen**
5. Press **`p`** to enter **Presenter Mode** — this opens a second window with:
   - Current slide + next slide preview
   - Speaker notes
   - Timer
6. **Drag the presenter window** to your laptop screen and the **fullscreen slides window** to the projector

### Keyboard shortcuts during the presentation

| Key | Action |
|-----|--------|
| `→` or `Space` | Next slide |
| `←` | Previous slide |
| `f` | Toggle fullscreen |
| `p` | Toggle presenter mode |
| `o` | Slides overview / grid |
| `d` | Toggle dark mode |
| `g` | Go to specific slide (type number) |
| `Esc` | Exit fullscreen / overview |

### Tips

- Use **Extend Display** (not Mirror) so you see presenter notes on your laptop while students see only the slides
- Bump up browser zoom (`Cmd +`) if the room is large and text looks small on the projector
- If the slide server stops, just re-run `npm run day1` — it picks up where you left off

