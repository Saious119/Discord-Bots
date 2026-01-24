# syntax=docker/dockerfile:1

FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY . .

# Install discord.py and other common dependencies
RUN pip install --no-cache-dir discord.py

# Create a non-privileged user
RUN useradd -m -u 1001 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Run the bot
CMD ["python", "purple_haro_bot.py"]
