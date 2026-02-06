# syntax=docker/dockerfile:1

FROM python:3.11-slim AS base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Create a non-privileged user that the app will run under.
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

# Install required Python packages for PurpleHaroBot
RUN pip install --no-cache-dir \
    discord.py \
    requests \
    pandas \
    nltk

# Download NLTK data as root before switching users
RUN python -c "import nltk; nltk.download('vader_lexicon'); nltk.download('punkt'); nltk.download('stopwords'); nltk.download('wordnet'); nltk.download('averaged_perceptron_tagger')"

# Switch to the non-privileged user to run the application.
USER appuser

# Copy the source code into the container.
COPY --chown=appuser:appuser . .

# Run the application using JSON format
CMD ["python3", "purple_haro_bot.py"]
