#!/usr/bin/env bash
set -Eeuo pipefail

REGION="us-west1"
REPO_DIR="${HOME}/pet-theory"
LAB_DIR="${REPO_DIR}/lab07"

log() { printf '\n\033[1;36m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }

PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
if [[ -z "${PROJECT_ID}" || "${PROJECT_ID}" == "(unset)" ]]; then
  PROJECT_ID="$(gcloud projects list --format='value(projectId)' --filter='projectId~^qwiklabs-gcp-' --limit=1)"
fi
if [[ -z "${PROJECT_ID}" ]]; then
  echo "ERROR: Lab project nahi mila. Pehle Cloud Shell me lab student account se login karke gcloud project set karein." >&2
  exit 1
fi

gcloud config set project "${PROJECT_ID}" >/dev/null
gcloud config set run/region "${REGION}" >/dev/null
gcloud config set run/platform managed >/dev/null

log "Project: ${PROJECT_ID} | Region: ${REGION}"
log "Required APIs enable kar raha hoon"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com containerregistry.googleapis.com --quiet

if [[ ! -d "${LAB_DIR}" ]]; then
  log "Pet Theory source repository clone kar raha hoon"
  git clone --depth=1 https://github.com/rosera/pet-theory.git "${REPO_DIR}"
fi

log "Task 1/2: public staging billing aur frontend build/deploy"
gcloud builds submit "${LAB_DIR}/unit-api-billing" \
  --tag "gcr.io/${PROJECT_ID}/billing-staging-api:0.1" --quiet
gcloud run deploy public-billing-service-967 \
  --image "gcr.io/${PROJECT_ID}/billing-staging-api:0.1" \
  --region "${REGION}" --platform managed --allow-unauthenticated --quiet

gcloud builds submit "${LAB_DIR}/staging-frontend-billing" \
  --tag "gcr.io/${PROJECT_ID}/frontend-staging:0.1" --quiet
gcloud run deploy frontend-staging-service-391 \
  --image "gcr.io/${PROJECT_ID}/frontend-staging:0.1" \
  --region "${REGION}" --platform managed --allow-unauthenticated --quiet

log "Task 3: private staging billing deploy"
gcloud run services delete public-billing-service-967 \
  --region "${REGION}" --platform managed --quiet || true
gcloud builds submit "${LAB_DIR}/staging-api-billing" \
  --tag "gcr.io/${PROJECT_ID}/billing-staging-api:0.2" --quiet
gcloud run deploy private-billing-service-368 \
  --image "gcr.io/${PROJECT_ID}/billing-staging-api:0.2" \
  --region "${REGION}" --platform managed --no-allow-unauthenticated --quiet

log "Task 4: billing service account create"
gcloud iam service-accounts create billing-service-sa-649 \
  --display-name="Billing Service Cloud Run" --quiet || true

log "Task 5: private production billing deploy"
gcloud builds submit "${LAB_DIR}/prod-api-billing" \
  --tag "gcr.io/${PROJECT_ID}/billing-prod-api:0.1" --quiet
gcloud run deploy billing-prod-service-261 \
  --image "gcr.io/${PROJECT_ID}/billing-prod-api:0.1" \
  --region "${REGION}" --platform managed \
  --no-allow-unauthenticated \
  --service-account="billing-service-sa-649@${PROJECT_ID}.iam.gserviceaccount.com" --quiet

log "Task 6: frontend service account aur Cloud Run Invoker permission"
gcloud iam service-accounts create frontend-service-sa-797 \
  --display-name="Billing Service Cloud Run Invoker" --quiet || true
gcloud run services add-iam-policy-binding billing-prod-service-261 \
  --region "${REGION}" --platform managed \
  --member="serviceAccount:frontend-service-sa-797@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/run.invoker" --quiet

log "Task 7: production frontend build/deploy"
gcloud builds submit "${LAB_DIR}/prod-frontend-billing" \
  --tag "gcr.io/${PROJECT_ID}/frontend-prod:0.1" --quiet
gcloud run deploy frontend-prod-service-261 \
  --image "gcr.io/${PROJECT_ID}/frontend-prod:0.1" \
  --region "${REGION}" --platform managed --allow-unauthenticated \
  --service-account="frontend-service-sa-797@${PROJECT_ID}.iam.gserviceaccount.com" --quiet

log "Verification"
printf '\nPublic staging frontend URL:\n%s\n' "$(gcloud run services describe frontend-staging-service-391 --region "${REGION}" --format='value(status.url)')"
printf '\nProduction frontend URL:\n%s\n' "$(gcloud run services describe frontend-prod-service-261 --region "${REGION}" --format='value(status.url)')"
printf '\nPrivate staging billing URL:\n%s\n' "$(gcloud run services describe private-billing-service-368 --region "${REGION}" --format='value(status.url)')"
printf '\nProduction billing URL:\n%s\n' "$(gcloud run services describe billing-prod-service-261 --region "${REGION}" --format='value(status.url)')"

cat <<'NOTE'

Cloud resources complete ho gaye hain. Google Cloud Skills Boost page par 30-60 seconds wait karke har task ka "Check my progress" click karein; script browser ke lab checker ko click nahi kar sakti.
NOTE
