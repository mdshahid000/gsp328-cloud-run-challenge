# GSP328 — Develop Serverless Applications on Cloud Run: Challenge Lab

This repository contains one Cloud Shell script that performs the seven Cloud Run challenge tasks in order.

## Run

```bash
curl -LO https://raw.githubusercontent.com/REPLACE_OWNER/REPLACE_REPO/main/Meow.sh
sudo chmod +x Meow.sh
./Meow.sh
```

The script detects the active `qwiklabs-gcp-*` project when no project is configured, sets `us-west1`, clones the Pet Theory source, builds the required images with Cloud Build, deploys the staging and production services, creates both service accounts, grants Cloud Run Invoker permission, and prints the resulting URLs.

## Important

Use the lab student account only. Do not put the temporary lab password in a script or GitHub. After the script finishes, wait approximately 30–60 seconds and click **Check my progress** for each task in the Skills Boost page. The script cannot click the browser-based lab checker.

Estimated execution time is usually 5–10 minutes, with an additional 30–60 seconds for activity tracking. Keep at least 20 minutes available in the lab session.
