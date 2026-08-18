# Practical Kubernetes Administration and Troubleshooting

**Instructor:** Chad M. Crowell  
**Duration:** 4 days  
**Location:** In-person  

---

## 🎯 Training Overview

This 4-day hands-on training covers practical Kubernetes administration from cluster setup through advanced troubleshooting. Each day includes guided labs in cloud-based environments.

📄 [Participant Guide](<assets/Participant Guide - Practical Kubernetes Administration and Troubleshooting_Date Feb 17-20th.pdf>) — course objectives, agenda, and instructor bio (from the Feb 17–20, 2026 cohort)

## 📚 Daily Schedule

### [Day 1: Foundations and Cluster Setup](day1/)
- Containers vs Virtual Machines
- Kubernetes Architecture
- Installing and Configuring Kubernetes
- **Labs:** Cluster provisioning, kubeadm setup, CNI deployment ([labs/](day1/labs/))

### [Day 2: Core Concepts and Workload Management](day2/)
- Managing Kubernetes Objects
- Command-Line Tools and Workflows
- **Labs:** Deployments, ConfigMaps, Secrets, Health Checks ([labs/](day2/labs/))

### [Day 3: Networking, Scheduling, and Storage](day3/)
- Kubernetes Networking
- Scheduling and Workload Distribution
- Persistent Storage
- Ingress and Gateway API
- **Labs:** Services, Ingress, Storage configuration, LoadBalancers ([labs/](day3/labs/))

### [Day 4: Security, Monitoring, and Troubleshooting](day4/)
- Security Essentials (RBAC, Network Policies)
- Monitoring and Observability
- Troubleshooting and Cluster Operations
- **Labs:** RBAC configuration, monitoring setup, cluster upgrades ([labs/](day4/labs/))

### [Capstone: The Notes App](capstone/)
- Cumulative lab combining Deployments, Services, storage, NetworkPolicies, RBAC, and troubleshooting from all four days
- Objective-driven (not command-by-command) with a full reference solution
- Optional disaster-recovery stretch goal using etcd backup/restore

### [Core Reference Pack](reference/)
- kubectl quick reference (commands, flags, common patterns)
- Kubernetes architecture & components cheat sheet
- CKA exam objectives → course map
- Printable PDFs alongside markdown source

---

## 🚀 Getting Started

### Prerequisites
- Basic Linux command-line experience
- Understanding of containerization concepts
- Laptop with SSH client

### Clone This Repository
```bash
git clone https://github.com/kubeskills/practical-k8s.git
cd practical-k8s
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

