# Contributing to AI Expense Tracker

Thank you for considering contributing to the AI Expense Tracker! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Convention](#commit-convention)
- [Pull Request Process](#pull-request-process)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/<your-username>/DevOps_main_project.git
   cd DevOps_main_project
   ```
3. **Set up** the development environment:
   ```bash
   cp .env.example .env
   docker compose up -d
   ```
4. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Backend (FastAPI)

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Run tests
python -m pytest tests/ -v

# Run linting
flake8 app/ --max-line-length=120
mypy app/
```

### Frontend (React)

```bash
cd frontend
npm install

# Start dev server
npm start

# Run tests
npm test

# Build production
npm run build
```

### Full Stack (Docker)

```bash
# Development
docker compose up -d

# Production
docker compose -f docker-compose.prod.yml up -d

# Run all checks
make test
make lint
```

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
[optional footer(s)]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style (formatting, no logic change) |
| `refactor` | Code refactoring |
| `test` | Adding/updating tests |
| `chore` | Build process, dependencies, CI |
| `ci` | CI/CD pipeline changes |
| `perf` | Performance improvements |

### Examples

```bash
feat(backend): add expense export to CSV
fix(frontend): resolve chart rendering on mobile
docs(readme): update architecture diagram
ci(actions): add Docker layer caching
chore(k8s): update resource limits
```

## Pull Request Process

1. **Update documentation** if your changes affect the public API or configuration
2. **Add/update tests** for any new functionality
3. **Ensure CI passes** — all GitHub Actions checks must be green
4. **Fill out the PR template** with a clear description
5. **Link related issues** using `Closes #123` syntax
6. **Request review** from at least one maintainer

### PR Title Format

Follow the same convention as commits:
```
feat(backend): add expense analytics caching
```

## Code Style

### Python (Backend)
- Follow [PEP 8](https://peps.python.org/pep-0008/) with max line length of 120
- Use type hints for all function signatures
- Use `async/await` for database operations
- Document public functions with docstrings

### JavaScript (Frontend)
- Use functional components with React Hooks
- Follow ESLint rules configured in the project
- Use meaningful component and variable names
- Keep components focused and reusable

### Docker
- Use multi-stage builds
- Run as non-root user
- Minimize layer count
- Use `.dockerignore` to exclude unnecessary files

### Kubernetes
- Include comments explaining non-obvious configurations
- Set resource requests AND limits on all containers
- Use labels consistently (`app`, `component`, `environment`)

## Reporting Issues

### Bug Reports

Include:
- **Description**: Clear description of the bug
- **Steps to Reproduce**: Numbered steps to reproduce
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: OS, Docker version, browser, etc.
- **Logs**: Relevant error logs or screenshots

### Feature Requests

Include:
- **Problem**: What problem does this solve?
- **Proposed Solution**: How would you implement it?
- **Alternatives**: Other approaches considered
- **Additional Context**: Mockups, references, etc.

---

Thank you for contributing! 🎉
