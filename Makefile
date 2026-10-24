# Makefile for common project commands

.PHONY: android-release bundle bump-version print-aab-path

android-release: bundle
	flutter build appbundle --release

bundle:
	@echo "Building Android release bundle..."
	flutter build appbundle --release

bump-version:
	@echo "Bumping version in pubspec.yaml (BUMP=$(BUMP))"
	python - <<'PY'
import os, re, pathlib
path = pathlib.Path('pubspec.yaml')
text = path.read_text()
match = re.search(r'^(version:\s*)(\d+)\.(\d+)\.(\d+)\+(\d+)', text, flags=re.M)
if not match:
    raise SystemExit('Unable to find version line in pubspec.yaml')
prefix, major, minor, patch, build = match.groups()
major, minor, patch, build = map(int, (major, minor, patch, build))
strategy = os.environ.get('BUMP', 'patch').lower()
if strategy == 'major':
    major += 1
    minor = 0
    patch = 0
elif strategy == 'minor':
    minor += 1
    patch = 0
elif strategy == 'build':
    pass
else:
    patch += 1
build += 1
new_version = f'{major}.{minor}.{patch}+{build}'
new_text = re.sub(r'^(version:\s*)\d+\.\d+\.\d+\+\d+', rf'\1{new_version}', text, flags=re.M)
path.write_text(new_text)
print(new_version)
PY

# Path to the generated Android App Bundle
AAB_PATH=build/app/outputs/bundle/release/app-release.aab

print-aab-path:
	@echo "Generated AAB file: $(AAB_PATH)"
