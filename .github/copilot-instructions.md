# WhatTimeNextTrain - AI Development Guide

## Project Overview

**WhatTimeNextTrain** is a full-stack web app showing the next train from a home location. It calculates when to leave home based on travel time, preparation time, and train schedules. Designed to run on Raspberry Pi with local network access.

## Architecture

### Backend (Python Flask)

- **Entry**: [backend/run.py](../backend/run.py) - starts Flask on port 5000
- **App Factory**: [backend/app/**init**.py](../backend/app/__init__.py) - creates Flask instance with CORS
- **Routes**: [backend/app/routes.py](../backend/app/routes.py) - API endpoints for `/health`, `/next-train`, `/all-trains`, `/profiles`
- **Models**: [backend/app/models.py](../backend/app/models.py) - `Train`, `TrainSchedule`, `NextTrainInfo` dataclasses
- **Services**:
  - [backend/app/services/timeCalculator.py](../backend/app/services/timeCalculator.py) - calculates departure times based on travel + prep time
  - [backend/app/services/trainScheduler.py](../backend/app/services/trainScheduler.py) - loads JSON schedules
- **Data Flow**: Profile → Load profile JSON → Load schedule JSON → TimeCalculator → Response

### Frontend (Vue 3 + TypeScript)

- **Vite build** with hot-reload in dev
- **Components**: [src/components/](../frontend/src/components/) - `StationHeader`, `CurrentTrainInfo`, `NextTrainInfo`, `LoadingErrorCard`, `ProfileSelector`
- **API Service**: [src/services/api.ts](../frontend/src/services/api.ts) - axios wrapper with timeout (10s)
- **Types**: [src/types/api.ts](../frontend/src/types/api.ts) - full TypeScript interfaces for all responses

### Data Storage

- Profiles: `backend/data/profile/profile_{name}.json` (defines travel time, prep time, schedule file reference)
- Schedules: `backend/data/schedule/train_schedule_{name}.json` (stores train data by day-of-week)
- JSON schema: schedules have weekday/weekend splits; each train has line, destination, departure_time, arrival_time (HH:MM format)

## Critical Workflows

### Local Development

```bash
# Backend (with uv)
cd backend && uv venv venv && source venv/bin/activate && uv pip install -r requirements.txt
python run.py  # runs on http://localhost:5000

# Frontend (separate terminal)
cd frontend && npm install && npm run dev  # runs on http://localhost:5173
```

### Testing

- `python backend/test_backend.py` - unit tests for models and time calculation (Exit code 1 means assertion failures)
- No frontend tests configured yet

### Startup Scripts (Windows)

- `start-services.ps1` - recommended, auto-detects issues, manages both services
- `start-services.bat` - simpler alternative, opens separate windows
- Both auto-open browser to `http://localhost:3000` (configurable port)

### Production (Raspberry Pi)

- `./setup-raspberry-pi.sh` - one-time setup (install Python3, Node.js, venv, dependencies)
- `./start-services.sh start` - daemonize both services
- systemd service files in [systemd/](../systemd/) for permanent hosting

## Key Patterns

### Config-Driven Development

- [backend/config.py](../backend/config.py) centralized: `PREPARATION_MINUTES`, `HOME_TO_STATION_MINUTES`, `CORS_ORIGINS`, `UPDATE_INTERVAL_SECONDS`
- Frontend uses env var `VITE_API_BASE_URL` for API endpoint (defaults to `http://localhost:5000/api`)

### Profile System

Routes support dynamic profiles via query param: `GET /api/next-train?profile=profile_name`
Each profile references a separate schedule JSON, enabling multi-station support

### Time Handling

- Always use Python `time` objects internally, JSON strings for API (HH:MM format)
- TimeCalculator assumes single day (no midnight crossing); handles weekday/weekend logic in models
- 1-minute polling from frontend (see STARTUP_GUIDE.md - UPDATE_INTERVAL_SECONDS)

### Component Responsibilities

- Frontend auto-reloads every 60s; countdown is client-side JavaScript
- Backend stateless (no session) - reads JSON on each request, no caching
- CORS restricted to `localhost:3000, 192.168.1.21:3000` (edit config.py for different IPs)

## Development Rules (from Rules.md)

1. **Code style**: camelCase for vars/functions, PascalCase for classes
2. **Comments**: Required on all functions and classes with description
3. **Class size**: Keep <150 lines; split larger classes
4. **Approval**: Request changes before merging
5. **Dependencies**: Explain why when adding packages
6. **Docs**: Update Readme.md when project structure changes

## Common Tasks

### Add New Train Schedule

1. Create `backend/data/schedule/train_schedule_{new_name}.json` (copy existing format)
2. Create `backend/data/profile/profile_{new_name}.json` referencing schedule file
3. Update CORS_ORIGINS in config.py if accessing from new IP
4. No backend restart needed - routes load JSON on request

### Debug API Failures

- Check `backend/test_backend.py` for expected model structure
- Verify JSON format: use `json.load()` in Python REPL to spot syntax errors
- Frontend logs API errors to console; check browser DevTools Network tab
- Backend errors return HTTP 500 with exception message

### Time Calculation Issues

- TimeCalculator uses: departure_time - (home_to_station_minutes + preparation_minutes)
- If midnight crossing occurs (e.g., 01:00 train, 20min travel), result wraps to previous day - known limitation
- Test with `test_backend.py` using mock datetime to verify edge cases

## External Dependencies

- **uv** - Fast Python package installer and virtual environment manager ([install](https://docs.astral.sh/uv/getting-started/installation/))
- **Flask 2.3.3** - lightweight web framework
- **Flask-CORS 4.0.0** - cross-origin requests (required for frontend on different port)
- **python-dateutil** - datetime utilities
- **APScheduler 3.10.4** - scheduled tasks (currently not actively used; reserved for future periodic updates)
- **Axios 1.6.0** - frontend HTTP client
- **Pinia 2.1.7** - state management (installed but minimal usage)

## Deployment Targets

- **Development**: Windows/Linux with `npm run dev` + `python run.py` in separate terminals
- **Production**: Raspberry Pi 3B+ with systemd services, runs headless on fixed IP
- Browser access: LAN clients point to Raspberry Pi hostname or IP
