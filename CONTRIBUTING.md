# Contributing to JDV GLOBAL CENTER

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Commit: `git commit -am 'Add new feature'`
6. Push: `git push origin feature/your-feature`
7. Open a Pull Request

## Development Setup

### Backend
```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

### Frontend
```bash
cd frontend
npm install
npm run dev
```

## Code Style

- Use TypeScript
- Follow ESLint rules
- Format with Prettier
- Write unit tests
- Document your code

## Commit Messages

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style
- `refactor:` Refactoring
- `test:` Tests
- `chore:` Maintenance

## Pull Request Process

1. Ensure CI passes
2. Update documentation
3. Add tests for new features
4. Request review from maintainers
5. Address feedback
6. Merge when approved
