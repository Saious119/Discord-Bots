# Fix for Insecure Registry Error

## Problem
k3s is trying to use HTTPS to connect to the local registry at `192.168.1.245:5000`, but the registry is serving over HTTP.

## Solution

On your **k3s cluster node** (Raspberry Pi or wherever k3s is running), run these commands:

### 1. Update k3s Registry Configuration

```bash
# Edit the registries.yaml file
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "192.168.1.245:5000":
    endpoint:
      - "http://192.168.1.245:5000"
  "localhost:5000":
    endpoint:
      - "http://localhost:5000"
configs:
  "192.168.1.245:5000":
    tls:
      insecure_skip_verify: true
  "localhost:5000":
    tls:
      insecure_skip_verify: true
EOF
```

### 2. Restart k3s to Apply Changes

```bash
sudo systemctl restart k3s
```

### 3. Verify Configuration

```bash
# Check if k3s is running
sudo systemctl status k3s

# Try to pull an image manually to test
sudo crictl pull 192.168.1.245:5000/andybot:latest
```

## Alternative: Use localhost:5000 Instead

If you're building and deploying on the same machine, you can update your deployments to use `localhost:5000` instead of `192.168.1.245:5000`, which is already configured in your registries.yaml.

However, if your build machine is different from your k3s node, using the IP address is correct and you need the configuration above.

## For containerd (if using standalone containerd)

If you're using containerd directly (not k3s), edit `/etc/containerd/config.toml`:

```toml
[plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.1.245:5000".tls]
  insecure_skip_verify = true

[plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.1.245:5000"]
  endpoint = ["http://192.168.1.245:5000"]
```

Then restart containerd:
```bash
sudo systemctl restart containerd
```
