# ========================================
# Stage 1: Build Admin Panel with Node.js
# ========================================
FROM node:20-slim AS admin-builder

WORKDIR /admin-build

# Copy admin panel package files
COPY admin-panel/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy admin panel source
COPY admin-panel/ ./

# Build admin panel (creates /admin-build/dist)
RUN npm run build

# ========================================
# Stage 2: Python Backend + Admin Static Files
# ========================================
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Python requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir uvicorn

# Copy backend application code
COPY . .

# Copy built admin panel from Stage 1
COPY --from=admin-builder /admin-build/dist /app/admin-dist

# Expose port (Hugging Face Spaces default: 7860)
EXPOSE 7860

# Start FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
