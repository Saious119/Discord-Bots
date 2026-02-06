# Dockerfile Corrections Summary

This document summarizes the corrections made to existing Dockerfiles and deployment configurations.

## Issues Found and Fixed

### 1. Go Bots (AndyBot, PirateBot, WSB)

**Issues:**
- Dockerfiles were building to generic `/bin/server` instead of bot-specific names
- Missing runtime data files (quotes text files)
- Missing proper working directory setup
- Deployment manifests incorrectly assumed `auth.json` when bots use `auth.txt`

**Corrections Made:**

#### AndyBot
- ✅ Changed build output from `/bin/server` to `/bin/andybot`
- ✅ Added `WORKDIR /app` for proper file location
- ✅ Added copy of `AndyQuotes.txt` to container
- ✅ Updated entrypoint to `/app/andybot`
- ✅ Uses `auth.txt` (not auth.json)

#### PirateBot
- ✅ Changed build output from `/bin/server` to `/bin/piratebot`
- ✅ Added `WORKDIR /app` for proper file location
- ✅ Added copy of `OnePieceQuotes.txt` to container
- ✅ Updated entrypoint to `/app/piratebot`
- ✅ Uses `auth.txt` (not auth.json)

#### WSB
- ✅ Changed build output from `/bin/server` to `/bin/wsb`
- ✅ Added `WORKDIR /app` for proper file location
- ✅ Added copy of `GamerQuotes.txt` to container
- ✅ Updated entrypoint to `/app/wsb`
- ✅ Uses `auth.txt` (not auth.json)

### 2. Node.js Bots (UwUBot, OyVeyBot)

**Status:** ✅ No changes needed - already correct
- UwUBot correctly uses `uwu.js` and `auth.json`
- OyVeyBot correctly uses `OyVeyBot.js` and `auth.json`

### 3. Python Bots (ScribeBot)

**Status:** ✅ No changes needed - already correct
- Correctly uses `scribe_bot.py` and requirements.txt
- Uses `auth.txt`

### 4. C# Bots (BrainCellBot, DickJohnson, MangaNotifier)

**Status:** ✅ No changes needed - already correct
- All follow standard .NET multi-stage build pattern
- All use `auth.txt`

## Kubernetes Configuration Updates

### Updated Files:

1. **`kubernetes/generate-deployments.sh`**
   - Changed Go bot auth mount from `auth.json` to `auth.txt`
   - Path: `/app/auth.txt` instead of `/app/auth.json`

2. **`kubernetes/deploy-all.sh`**
   - Updated secret creation for Go bots to use `auth.txt`
   - Changed from `auth.json` to `auth.txt` for AndyBot, PirateBot, WSB

3. **`kubernetes/secrets/README.md`**
   - Updated documentation to reflect Go bots use `auth.txt`
   - Corrected example commands
   - Updated bulk secret creation script

4. **`kubernetes/deployments/andybot.yaml`**
   - Updated volume mount to use `auth.txt`
   - Fixed indentation for consistency

5. **`DEPLOYMENT-CHECKLIST.md`**
   - Updated checklist to show correct auth file types
   - Go bots: `auth.txt`
   - Node.js bots: `auth.json`
   - C# bots: `auth.txt`
   - Python bots: `auth.txt`

6. **`DEPLOYMENT-QUICKSTART.md`**
   - Updated secret creation examples
   - Clarified which bots use which auth file types

## Auth File Types by Language

| Language | Bots | Auth File |
|----------|------|-----------|
| **Go** | AndyBot, PirateBot, WSB | `auth.txt` |
| **C#** | BrainCellBot, DickJohnson, HouseMog, MangaNotifier, MovieNightBot | `auth.txt` |
| **Node.js** | OwOBot, OyVeyBot, RedditSimBot, TarotBot, UwUBot, JailBot, JonTronBot, TerryDavisBot | `auth.json` |
| **Python** | ScribeBot, PurpleHaroBot | `auth.txt` |

## What This Means for Deployment

### Secret Creation
When creating secrets, use the correct file type:

```bash
# Go bots
kubectl create secret generic andybot-secret \
  --from-file=auth.txt=AndyBot/auth.txt \
  --namespace=discord-bots

# Node.js bots
kubectl create secret generic owobot-secret \
  --from-file=auth.json=OwOBot/auth.json \
  --namespace=discord-bots

# C# bots
kubectl create secret generic braincellbot-secret \
  --from-file=auth.txt=BrainCellBot/auth.txt \
  --namespace=discord-bots

# Python bots
kubectl create secret generic scribebot-secret \
  --from-file=auth.txt=ScribeBot/auth.txt \
  --namespace=discord-bots
```

### Volume Mounts
Deployment manifests now correctly mount:
- Go bots: `/app/auth.txt`
- C# bots: `/app/auth.txt`
- Node.js bots: `/app/auth.json`
- Python bots: `/app/auth.txt`

## Runtime Data Files

Go bots now include their required data files in the container:
- **AndyBot**: Includes `AndyQuotes.txt`
- **PirateBot**: Includes `OnePieceQuotes.txt`
- **WSB**: Includes `GamerQuotes.txt`

These files are copied during the Docker build and are available at runtime in `/app/`.

## Testing the Corrections

After these corrections, you should:

1. **Rebuild Go bot images:**
   ```bash
   docker build -t localhost:5000/andybot:latest AndyBot/
   docker build -t localhost:5000/piratebot:latest PirateBot/
   docker build -t localhost:5000/wsb:latest WSB/
   ```

2. **Verify the images contain the correct files:**
   ```bash
   docker run --rm localhost:5000/andybot:latest ls -la /app/
   # Should show: andybot, AndyQuotes.txt
   ```

3. **Regenerate deployment manifests:**
   ```bash
   cd kubernetes
   ./generate-deployments.sh
   ```

4. **Deploy with corrected configurations:**
   ```bash
   ./deploy-all.sh
   ```

## All Corrections Complete ✅

All Dockerfiles and Kubernetes configurations have been corrected and are now ready for deployment.

The automated scripts (`build-all.sh`, `deploy-all.sh`, `generate-deployments.sh`) now use the correct configurations for all bots.