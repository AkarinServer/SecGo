# Contributing to SecGo

Thanks for helping improve SecGo! This repo enforces a **PR-first** workflow and requires CI to pass before merging to `main`.

---

## ✅ Workflow Summary

1. **Create a branch** off `main`.
2. **Make changes locally**.
3. **Run checks locally** (lint + tests).
4. **Open a PR** into `main`.
5. **Wait for CI** to pass and get at least **1 approval**.
6. **Merge via PR** (no direct pushes to `main`).

---

## 🌿 Branch Naming

Use a descriptive prefix:

- `feature/<short-desc>` — new features
- `fix/<short-desc>` — bug fixes
- `chore/<short-desc>` — tooling, docs, refactors
- `docs/<short-desc>` — documentation only

Examples:
- `feature/kiosk-scan-overlay`
- `fix/manager-sync-timeout`
- `chore/ci-main-only`

---

## 🧪 Local Checks

Run these from the app folders before opening a PR:

### Kiosk
```bash
cd Kiosk
flutter pub get
flutter analyze
flutter test
```

### Manager
```bash
cd Manager
flutter pub get
flutter analyze
flutter test
```

> Integration tests are optional locally (device required) but encouraged when touching user flows.

---

## 🧷 Environment Setup

Use the provided templates:

- `Kiosk/.env_template`
- `Manager/.env_template`

Copy to `.env` and fill values:
```bash
cp Kiosk/.env_template Kiosk/.env
cp Manager/.env_template Manager/.env
```

---

## ✅ PR Requirements

- **At least 1 approval**
- **CI passes** (lint + tests)
- **No direct pushes** to `main`

---

## 🔢 Versioning Rule (Main Merge)

Every merge into `main` **must** bump the app "major" version by **+1**.

For this repo, while versions are still in `0.x.y`, we treat the **`x`** as the
major version. That means **`0.x → 0.(x+1)`** on every merge.

Update both of these files before merging:

- `Kiosk/pubspec.yaml`
- `Manager/pubspec.yaml`

Example:

```
0.1.3+4 → 0.2.0+1
```

---

## 🧾 Commit Style

Keep commits small and meaningful. Suggested format:

```
<type>: <short summary>

- bullet 1
- bullet 2
```

Examples:
- `feat: add kiosk pairing retry`
- `fix: handle null barcode in scanner`
- `chore: update ci workflow`

---

Thanks for contributing! 🙌
