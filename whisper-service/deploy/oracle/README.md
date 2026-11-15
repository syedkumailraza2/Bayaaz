# Deploy the STT service on Oracle Cloud (Always Free)

Oracle's Always Free tier includes Ampere A1 ARM VMs with up to **4 OCPUs and
24 GB RAM** in total. That's enough for about 40+ simultaneous follow-my-voice
speakers (measured: 40 streams = 3 cores, 1.9 GB, <0.5 s lag).

## 1. Create the VM (Oracle console, one time)
1. Sign up at cloud.oracle.com. Pick a home region close to your users; it
   can't be changed later.
2. **Compute → Instances → Create instance**
   - Image: **Canonical Ubuntu 24.04** (pick the aarch64 build).
   - Shape: **Ampere → VM.Standard.A1.Flex**, 4 OCPU / 24 GB (or 2 / 12).
   - Networking: create a new VCN with a public subnet, and assign a public IPv4.
   - SSH keys: upload `~/.ssh/id_ed25519.pub` (or let Oracle generate one).
   - If you get "Out of capacity", try another availability domain or retry later.
3. **Networking → VCN → your subnet → Security list → Add ingress rules**:
   source `0.0.0.0/0`, TCP, destination ports **80** and **443**.
4. *Recommended:* upgrade the account to **Pay As You Go**. Always Free
   resources stay free, and Oracle stops reclaiming "idle" free VMs.
   Set a budget alert at $1 as a safety net.

## 2. DNS (Cloudflare)
Add an **A record** `stt` → the VM's public IP with **Proxy status: DNS only**
(grey cloud), so Caddy can issue the HTTPS certificate.

## 3. Prepare the VM (one time)
```bash
scp whisper-service/deploy/oracle/setup-vm.sh ubuntu@<vm-ip>:
ssh ubuntu@<vm-ip> 'bash setup-vm.sh'
```

## 4. Deploy (and later, every update)
From the repo root on your Mac:
```bash
whisper-service/deploy/oracle/deploy.sh ubuntu@<vm-ip> stt.mybayaaz.com
curl https://stt.mybayaaz.com/health     # {"status":"ok","streams":0,...}
```
The first run prints a generated `STT_TOKEN`. It is saved on the VM in
`~/bayaaz-stt/deploy/oracle/.env`.

## 5. Point the backend at it (Render → bayaaz-r9oe → Environment)
```
STT_URL=https://stt.mybayaaz.com
STT_TOKEN=<token from step 4>
```
Remove `VOSK_URL` / `WHISPER_HTTP_URL` if they're set; they take priority over
`STT_URL`. Save, let Render redeploy, then test follow-my-voice in the app. Once
it works, **suspend the old `bayaaz-stt` Render service**, which frees its free hours.

## Operating it
| Task | Command (on the VM, in `~/bayaaz-stt/deploy/oracle`) |
|---|---|
| Logs | `docker compose logs -f stt` |
| Live load | `curl -s localhost/health -H 'Host: stt.mybayaaz.com'`, or `curl https://stt.mybayaaz.com/health` |
| Restart | `docker compose restart stt` |
| Tune | edit `.env` (`STT_MAX_STREAMS`, `STT_THREADS`…), then `docker compose up -d` |

Containers restart automatically on crash or reboot (`restart: unless-stopped`).
