# Multi-stage build for security and size optimization
FROM python:3.12-slim AS builder

WORKDIR /app

# Install dependencies in builder stage
COPY requirements.txt ./
RUN pip install --no-cache-dir --user -r requirements.txt

# Final stage - minimal runtime image
FROM python:3.12-slim

WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser \
    && chown -R appuser:appuser /app

# Copy only necessary files from builder
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .

# Set PATH for user-installed packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Switch to non-root user
USER appuser

# Expose only necessary port
EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:80/healthz').read()" || exit 1

# Run application
CMD ["gunicorn", "-b", "0.0.0.0:80", "-w", "1", "--timeout", "30", "app:app"]