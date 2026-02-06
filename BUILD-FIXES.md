# Build Issues and Fixes

This document describes issues encountered during the Docker build process and their solutions.

## Issues Found During Build

### 1. ScribeBot - TensorFlow Dependency Issue

**Problem:**
- `requirements.txt` included TensorFlow with a Mac-specific wheel URL
- TensorFlow is not needed for ScribeBot functionality
- Build failed on ARM64 (Raspberry Pi) architecture

**Solution:**
- Created `requirements-minimal.txt` with only necessary packages:
  - `discord.py==2.3.2`
  - `requests==2.31.0`
  - `aiohttp==3.12.14`
- Updated Dockerfile to use minimal requirements
- ScribeBot only needs Discord.py and requests for its functionality

**Files Changed:**
- `ScribeBot/Dockerfile` - Use minimal requirements
- `ScribeBot/requirements-minimal.txt` - NEW file with minimal deps

### 2. PurpleHaroBot - NLTK Data Download

**Problem:**
- Bot uses NLTK for sentiment analysis
- NLTK data needs to be downloaded at build time
- Original Dockerfile didn't handle NLTK data properly

**Solution:**
- Updated Dockerfile to install required packages:
  - `discord.py`
  - `requests`
  - `pandas`
  - `nltk`
- Pre-download NLTK data during build:
  - `vader_lexicon` - for sentiment analysis
  - `punkt` - for tokenization
  - `stopwords` - for text preprocessing
  - `wordnet` - for lemmatization
  - `averaged_perceptron_tagger` - for POS tagging
- Download as root before switching to non-privileged user

**Files Changed:**
- `PurpleHaroBot/Dockerfile` - Complete rewrite with proper NLTK setup

### 3. Docker Build Warnings

**Warnings:**
- `FromAsCasing`: Mixed case in `FROM` and `AS` keywords
- `JSONArgsRecommended`: CMD should use JSON array format

**Solution:**
- Changed all `FROM ... as ...` to `FROM ... AS ...` (uppercase AS)
- Changed `CMD python3 script.py` to `CMD ["python3", "script.py"]`

**Applied to:**
- ScribeBot/Dockerfile
- PurpleHaroBot/Dockerfile

## Architecture Considerations

### Raspberry Pi (ARM64) Compatibility

**Issues:**
- Some Python packages don't have pre-built ARM64 wheels
- TensorFlow installation is problematic on ARM
- Build times can be longer on Raspberry Pi

**Best Practices:**
1. **Minimize dependencies** - Only install what's actually needed
2. **Use slim base images** - `python:3.11-slim` instead of full images
3. **Pre-download data** - NLTK data, models, etc. during build
4. **Avoid heavy ML libraries** - Unless absolutely necessary (TensorFlow, PyTorch)

## Dependency Analysis by Bot

### ScribeBot
**What it does:** Scrapes Discord quotes and updates other bots
**Actual dependencies:**
- ✅ discord.py - Discord API
- ✅ requests - HTTP calls to other bots
- ❌ tensorflow - NOT NEEDED
- ❌ tensorboard - NOT NEEDED
- ❌ numpy - NOT NEEDED (unless for specific feature)

### PurpleHaroBot
**What it does:** Sentiment analysis on messages
**Actual dependencies:**
- ✅ discord.py - Discord API
- ✅ nltk - Natural Language Processing
- ✅ pandas - Data manipulation
- ✅ requests - HTTP requests
- ✅ NLTK data files - Required for sentiment analysis

## Build Order Recommendations

For faster builds on Raspberry Pi, build in this order:

1. **Go bots** (fast builds):
   - AndyBot
   - PirateBot
   - WSB

2. **Simple Node.js bots** (medium builds):
   - OwOBot
   - OyVeyBot
   - JailBot
   - JonTronBot
   - TerryDavisBot
   - TarotBot

3. **Node.js bots with dependencies** (medium builds):
   - RedditSimBot (MongoDB client)
   - UwUBot (more dependencies)

4. **C# bots** (slower builds due to .NET compilation):
   - BrainCellBot
   - DickJohnson
   - HouseMog
   - MangaNotifier
   - MovieNightBot

5. **Python bots** (variable build times):
   - ScribeBot (fast with minimal deps)
   - PurpleHaroBot (slower due to NLTK data download)

## Testing Individual Builds

Before running `build-all.sh`, test problematic bots individually:

```bash
# Test ScribeBot
cd ScribeBot
docker build -t localhost:5000/scribebot:latest .

# Test PurpleHaroBot
cd ../PurpleHaroBot
docker build -t localhost:5000/purpleharobot:latest .

# If successful, run full build
cd ..
./build-all.sh
```

## Troubleshooting Build Failures

### Python Package Installation Failures

**Symptom:** `pip install` fails with compilation errors

**Solutions:**
1. Check if package has ARM64 wheels: https://pypi.org/
2. Install build dependencies in Dockerfile:
   ```dockerfile
   RUN apt-get update && apt-get install -y gcc g++ make
   ```
3. Use alternative packages or versions
4. Remove unnecessary dependencies

### Out of Memory During Build

**Symptom:** Build process killed, no error message

**Solutions:**
1. Build bots one at a time instead of `build-all.sh`
2. Increase swap space on Raspberry Pi:
   ```bash
   sudo dphys-swapfile swapoff
   sudo nano /etc/dphys-swapfile
   # Set CONF_SWAPSIZE=2048
   sudo dphys-swapfile setup
   sudo dphys-swapfile swapon
   ```
3. Use multi-stage builds to reduce final image size
4. Clean up Docker cache: `docker system prune -a`

### Slow Build Times

**Solutions:**
1. Use Docker BuildKit: `export DOCKER_BUILDKIT=1`
2. Enable build cache in registry
3. Build during off-hours
4. Consider building on a more powerful machine and pushing to registry

## Quick Reference: Fixed Dockerfiles

### ScribeBot
```dockerfile
# Uses requirements-minimal.txt
# Only installs: discord.py, requests, aiohttp
# Removed: tensorflow, tensorboard, numpy
```

### PurpleHaroBot
```dockerfile
# Installs: discord.py, requests, pandas, nltk
# Pre-downloads NLTK data during build
# Uses JSON CMD format
```

## Verification

After fixes, verify builds work:

```bash
# Build individually
docker build -t localhost:5000/scribebot:latest ScribeBot/
docker build -t localhost:5000/purpleharobot:latest PurpleHaroBot/

# Check image sizes
docker images | grep localhost:5000

# Test run (should fail without auth but container should start)
docker run --rm localhost:5000/scribebot:latest echo "Build OK"
```

## All Fixed ✅

Both problematic bots (ScribeBot and PurpleHaroBot) now have working Dockerfiles that:
- Build successfully on ARM64 (Raspberry Pi)
- Use minimal dependencies
- Follow Docker best practices
- Use non-root users for security
- Use JSON CMD format for proper signal handling