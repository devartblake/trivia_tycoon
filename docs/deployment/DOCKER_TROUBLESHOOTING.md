# Docker Troubleshooting Guide

## Container Error: "service didn't complete successfully: exit 1"

If you see this error when starting a Docker container:
```
Container synaptix_migration error service "migration" didn't complete successfully: exit 1
```

This indicates a container service failed to start or complete a task.

## Diagnosis Steps

### 1. Check Container Logs
```bash
# View logs for the failed service
docker-compose logs migration

# Or with more context
docker-compose logs -f migration  # Follow logs in real-time
```

### 2. Inspect Container State
```bash
# List all containers and their status
docker-compose ps

# Check container details
docker-compose ps migration

# Expected: status should be "Up" or "Exited with code 0" (success)
```

### 3. Common Causes

| Error | Cause | Solution |
|-------|-------|----------|
| `exit 1` | Generic failure | Check logs, see below |
| `exit 127` | Command not found | Verify docker image has all dependencies |
| `exit 128` | Invalid argument | Check docker-compose.yml syntax |
| Port already in use | Another process on same port | `lsof -i :5000` to find and kill |
| No database connection | Database not running | Start database container first |
| Migration script failed | Database schema mismatch | Check migration SQL syntax |

## Common Solutions

### Rebuild from scratch
```bash
# Stop all containers
docker-compose down

# Remove unused images/volumes
docker-compose down -v

# Rebuild everything
docker-compose up --build -d
```

### Start services in correct order
```bash
# Start database first
docker-compose up -d postgres

# Wait for database to be ready
sleep 10

# Then start other services
docker-compose up -d
```

### View service output
```bash
# Attach to service and see output
docker-compose logs -f migration

# Run command directly in container
docker-compose exec migration bash

# Inside container, run diagnostics
ps aux               # List processes
env | grep DATABASE  # Check environment variables
```

### Check configuration
```bash
# Validate docker-compose.yml
docker-compose config

# Check if all required images exist
docker images

# Verify environment files are loaded
docker-compose config | grep -A 10 migration
```

## Migration Specific Issues

### Database Migration Failed

**Error**: "Migration failed to complete"

**Causes**:
- Database not ready when migration runs
- Migration SQL syntax error
- Missing database permissions
- Schema already exists

**Solution**:
```bash
# 1. Stop all containers
docker-compose down

# 2. Remove database volume to start fresh
docker volume rm synaptix_migration_db_data

# 3. Start fresh
docker-compose up --build -d

# 4. Monitor logs
docker-compose logs -f migration
```

### Port Conflict

**Error**: "bind: address already in use"

**Solution**:
```bash
# Find what's using port 5000
lsof -i :5000

# Kill the process
kill -9 <PID>

# Or change port in docker-compose.yml
# Change "5000:5000" to "5001:5000"
```

### Image Build Failed

**Error**: "error during connect: This error may indicate the docker daemon is not running"

**Solution**:
```bash
# Ensure Docker is running
docker version

# If not running, start Docker Desktop (macOS/Windows) or daemon (Linux)
systemctl start docker  # Linux

# Try building again
docker-compose build --no-cache
```

## Frontend Connection to Docker Backend

### Test from Flutter App

```bash
# Check if backend is accessible from app
flutter run

# Monitor connection logs
flutter logs | grep -i "env\|health\|connection"

# Expected output:
# [EnvConfig] API Base: http://10.0.2.2:5000
# ✓ Health check passed
```

### If Connection Fails

1. **Check backend is running**:
   ```bash
   docker-compose ps
   # Status should show "Up"
   ```

2. **Verify port mapping**:
   ```bash
   docker-compose ps migration
   # Check "Ports" column shows 5000->5000
   ```

3. **Test health endpoint directly**:
   ```bash
   # From your machine
   curl -v http://localhost:5000/healthz
   
   # From Android emulator
   adb shell curl -v http://10.0.2.2:5000/healthz
   ```

4. **Check network connectivity**:
   ```bash
   # Android emulator
   adb shell ping 10.0.2.2
   
   # iOS simulator
   ping localhost
   ```

## Advanced Troubleshooting

### Access container shell
```bash
# Open bash in migration container
docker-compose exec migration bash

# Once inside, run diagnostics
ps aux
env
netstat -tlnp
cat /etc/hosts
```

### View raw container output
```bash
# Get container ID
docker-compose ps migration
CONTAINER_ID=$(docker-compose ps -q migration)

# Inspect logs without docker-compose
docker logs -f $CONTAINER_ID
```

### Clean slate reset
```bash
# Remove everything related to this project
docker-compose down -v
docker system prune -f

# Rebuild
docker-compose build --no-cache
docker-compose up -d

# Check status
docker-compose logs
```

## Debugging with env file

Create `.env` for debugging (never commit):
```bash
# .env (for docker-compose)
DATABASE_URL=postgres://user:pass@postgres:5432/trivia_tycoon
DEBUG=true
LOG_LEVEL=debug
API_PORT=5000
```

Then:
```bash
docker-compose --env-file .env up -d
```

## Health Check

Verify backend is healthy:
```bash
# Continuous health check
while true; do
  curl -s http://localhost:5000/healthz | jq .
  sleep 2
done
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-06-22T10:00:00Z",
  "services": {
    "database": "connected",
    "cache": "connected"
  }
}
```

## Getting Help

If you're still stuck:

1. **Collect logs**:
   ```bash
   docker-compose logs > debug.log
   ```

2. **Include in error report**:
   - Error message
   - Output of `docker-compose ps`
   - Output of `docker-compose logs migration`
   - Output of `docker-compose config`

3. **Check documentation**:
   - [CONNECTION_TESTING.md](CONNECTION_TESTING.md) - Connection verification
   - [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md) - Build configuration
   - [ENV_SETUP.md](ENV_SETUP.md) - Environment configuration

## Related Documentation

- [CONNECTION_TESTING.md](CONNECTION_TESTING.md) - How to test backend connectivity
- [ENV_SETUP.md](ENV_SETUP.md) - Environment configuration
- [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md) - Build and deployment
