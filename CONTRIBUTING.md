# Contributing to Poke: Iring

Thank you for your interest in contributing to Poke: Iring. This document provides guidelines and workflows for submitting bug reports, suggesting features, and opening pull requests.

---

## Code of Conduct

All contributors and maintainers are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). Please treat all members of the community with dignity, empathy, and respect.

---

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing issues to ensure the problem has not already been reported.

When opening an issue, provide:
1. A clear and descriptive title.
2. Steps to reproduce the behavior.
3. Expected vs. actual behavior.
4. Environment details: Flutter version (`flutter --version`), device or OS, and reproduction logs.

Please use the provided [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md).

### Proposing Enhancements

Feature requests and design ideas are welcomed:
1. Use the [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md).
2. Clearly describe the problem your feature solves or the value it brings to players.
3. Outline how the feature should behave and discuss potential architectural impacts.

---

## Development Workflow

### 1. Fork & Clone

Fork the repository to your GitHub account and clone your fork locally:

```bash
git clone https://github.com/<your-username>/Poke-Iring.git
cd Poke-Iring
```

### 2. Branching Strategy

Create a branch with a descriptive name following this format:

- `feature/<short-description>`: New features or capabilities
- `bugfix/<short-description>`: Bug fixes and issue patches
- `docs/<short-description>`: Documentation additions or fixes
- `refactor/<short-description>`: Code structure improvements without behavior change
- `test/<short-description>`: Adding or modifying test suites

Example:
```bash
git checkout -b feature/cat-rarity-calculator
```

### 3. Dependencies & Setup

Ensure all dependencies are synced:

```bash
flutter pub get
```

### 4. Code Formatting and Static Analysis

All code must pass Flutter's static analysis and formatting rules before being merged:

```bash
# Format Dart code automatically
dart format .

# Check for warnings or lint errors
flutter analyze
```

### 5. Automated Tests

Ensure all existing tests pass and add unit/widget tests for new functionality:

```bash
flutter test
```

Pull requests with broken tests or failing analyzer warnings will not be merged.

---

## Commit Guidelines

We follow the Conventional Commits specification:

```
<type>(<optional scope>): <description>
```

Common types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Formatting changes that do not affect code logic
- `refactor`: Refactoring production code
- `test`: Adding or correcting tests
- `chore`: Updating dependencies, build scripts, or configurations

Example:
```
feat(scanner): add tflite breed inference processor
fix(map): resolve missing location permission crash on android 14
```

---

## Submitting Pull Requests

1. Push your branch to your fork:
   ```bash
   git push origin feature/your-branch-name
   ```
2. Open a Pull Request targeting the `main` branch of the upstream repository.
3. Complete all sections of the [Pull Request Template](.github/pull_request_template.md).
4. Verify that all automated GitHub Actions CI checks pass.
5. Address review feedback promptly. Maintainers will review and merge approved contributions.
