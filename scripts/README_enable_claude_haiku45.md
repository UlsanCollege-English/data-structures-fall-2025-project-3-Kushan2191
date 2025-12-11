Enable Claude Haiku 4.5 — Automation template

What this is
- A PowerShell template (`enable_claude_haiku45.ps1`) to help enable the model for all clients.
- This template is intentionally generic because vendors expose different admin APIs.

How to use
1. Open `scripts\enable_claude_haiku45.ps1` and edit the endpoint variables near the top:
   - `$exampleAEndpoint` or `$exampleBEndpoint` must be set to your vendor's admin API URL/path.
   - Adjust `$exampleABody` or `$exampleBBody` to the JSON shape your vendor expects.

2. Run a dry run to confirm the request shapes (no changes will be made):
```powershell
cd .\\scripts
./enable_claude_haiku45.ps1 -ApiUrl "https://admin.vendor.example" -ApiKey "MY_ADMIN_KEY" -DryRun
```

3. If the dry run output looks correct, run without `-DryRun` to apply the change:
```powershell
./enable_claude_haiku45.ps1 -ApiUrl "https://admin.vendor.example" -ApiKey "MY_ADMIN_KEY"
```

Notes & safety
- Always test in a staging environment first.
- The script uses `Invoke-RestMethod` and will attempt `PATCH` then `POST` as a fallback.
- Replace placeholders with the exact admin API endpoints for your vendor (Anthropic, Anthropic-like, internal feature-flag service, etc.).

If you provide the vendor name and an example admin API endpoint, I can modify the script to call the exact API shape and include smoke-test requests as well.

CI / Autograder note
--------------------

- This repository's GitHub Actions autograder installs dependencies before running tests. The autograder setup currently runs:
   `python -m pip install --upgrade pip; if [ -f requirements.txt ]; then pip install -r requirements.txt; fi; python -m pip install pytest`
- If your project needs additional test dependencies, add them to `requirements.txt` or update the autograder workflow in `.github/workflows/classroom.yml`.
- Run the diagnostic workflow (`.github/workflows/diagnose-tests.yml`) or check the Actions logs when tests fail — they include environment, installed packages, and pytest output to help debug `INTERNALERROR` issues.
