# Contributing Guidelines

Thank you for your interest in contributing to this project! We appreciate your help in making it better. Please follow these guidelines to ensure a smooth collaboration.

## Getting Started

1. **Fork the Repository** – Click the "Fork" button on GitHub to create a personal copy.
2. **Clone Your Fork** – Use the following command to clone your fork:
   ```sh
   git clone https://github.com/your-username/repository-name.git
   ```
3. **Create a Branch** – Always create a new branch for your contributions:
   ```sh
   git checkout -b feature-branch
   ```

## Making Changes

- Keep changes **focused and concise**.
- Follow the existing **coding style and conventions**.
- Write **clear and descriptive commit messages**.
- If modifying scripts, ensure they have the **correct executable permissions** (`chmod +x`).
- **Use English for all comments, commit messages, and documentation.**

## Code Style and Best Practices

### Shell Scripts (`.sh`)
- Follow **POSIX-compliant syntax** when possible.
- Use `shellcheck` to lint scripts and catch common issues.
- Ensure all scripts are executable:
  ```sh
  chmod +x script.sh
  ```
- Avoid hardcoding paths; use environment variables where appropriate.

### Dockerfile
- Use **official base images** when possible.
- Minimize the number of layers to optimize image size.
- Avoid running processes as `root`; use a dedicated user instead.
- Use `COPY` instead of `ADD` unless necessary.
- Clean up unnecessary files to reduce image size.

### Windows Batch Files (`.bat`)
- Use **clear variable names** and avoid hardcoded paths.
- Ensure compatibility with Windows versions.
- Follow best practices for handling errors (e.g., using `IF ERRORLEVEL`).

## Commit Message Format

Use clear and structured commit messages:
```sh
feat: Add new feature
fix: Resolve issue with X
chore: Update dependencies
```

## Pull Requests

1. **Sync with the latest changes** before creating a PR:
   ```sh
   git fetch origin
   git rebase origin/main
   ```
2. **Push your branch**:
   ```sh
   git push origin feature-branch
   ```
3. **Open a Pull Request** – Provide a clear title and description of your changes.

## Reporting Issues

- Use the **issue tracker** to report bugs or request features.
- Provide **clear reproduction steps** and expected behavior.
- Attach **screenshots or logs** if applicable.

## Code of Conduct

Be respectful and have decency. Harassment and discrimination of any kind are not tolerated.

---

Thank you for contributing! 🚀

