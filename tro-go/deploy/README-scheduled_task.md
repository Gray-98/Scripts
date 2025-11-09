# Scheduling automated run for hj installer (option 6)

This folder contains example files and instructions to run the remote `trojan-go.sh` installer and automatically choose option 6.

Files added:
- `../scripts/run_hj.expect` - Expect (Tcl) script that runs the remote installer and sends `6` + Enter.
- `../scripts/run_hj.sh` - Bash wrapper that ensures `expect` is installed and runs the Expect script.
- `run-hj.service` - Example systemd service (oneshot). Update ExecStart to the correct path.
- `run-hj.timer` - Example systemd timer that triggers the service daily.

Recommended install steps (on Debian):

1. Copy scripts to a system location (example uses `/usr/local/bin`):

```bash
sudo cp scripts/run_hj.sh /usr/local/bin/run_hj.sh
sudo cp scripts/run_hj.expect /usr/local/bin/run_hj.expect
sudo chmod +x /usr/local/bin/run_hj.sh /usr/local/bin/run_hj.expect
```

2. (Optional) Test manually:

```bash
# Run interactively and watch the installer run; the expect script will send '6' automatically.
/usr/local/bin/run_hj.sh
```

3. Install systemd unit and timer (as root):

```bash
sudo cp deploy/run-hj.service /etc/systemd/system/run-hj.service
sudo cp deploy/run-hj.timer /etc/systemd/system/run-hj.timer
sudo systemctl daemon-reload
sudo systemctl enable --now run-hj.timer
sudo systemctl status run-hj.timer
```

The `run-hj.timer` above is configured for `OnCalendar=daily`. Change it if you need different scheduling.

Alternative: Cron job

If you prefer cron, add a root cron entry (edit with `sudo crontab -e`):

```cron
# Run at 03:00 every day
0 3 * * * /usr/local/bin/run_hj.sh >> /var/log/run_hj.log 2>&1
```

Notes and caveats
- This automates an installer fetched from the internet. Ensure you trust the remote script before scheduling automated runs.
- The Expect script is conservative: it looks for common prompt words and sends `5` when it sees them; it also sends a fallback `5` after a short delay. If the remote installer requires additional interactive inputs, you must extend the Expect script to handle them.
- Running installers as `root` carries risk. Prefer testing in a safe environment first.

If you want, I can also:
- Add a small systemd service that logs output to a file or rotates logs.
- Extend the Expect script to handle more specific prompts from the installer.

One-step install (after clone)

To make this repository "傻瓜式"：在仓库根目录新增了 `install.sh`。在服务器上 clone 本仓库后，在仓库根目录运行：

```bash
# From the repo root (where you see install.sh)
./install.sh
```

该脚本会自动提升为 root（使用 sudo），安装 `expect`（通过 apt-get），把脚本复制到 `/usr/local/bin`，并安装与启用 systemd 的 `run-hj.timer`。完成后会提示如何查看状态和手动触发一次运行。
