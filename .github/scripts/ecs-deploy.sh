#!/usr/bin/env bash
# Register a new ECS task definition revision with IMAGE and wait until
# the service is stable. Exit non-zero if ECS does not stabilize so the
# circuit breaker can roll back without a "successful" CI job.
set -euo pipefail

: "${AWS_REGION:?}"
: "${ECS_CLUSTER:?}"
: "${ECS_SERVICE:?}"
: "${ECS_TASK_FAMILY:?}"
: "${IMAGE:?}"
: "${HEALTH_URL:?}"

echo "Deploying ${IMAGE} to ${ECS_CLUSTER}/${ECS_SERVICE}"

task_def_json="$(mktemp)"
new_task_def_json="$(mktemp)"
trap 'rm -f "${task_def_json}" "${new_task_def_json}"' EXIT

aws ecs describe-task-definition \
  --region "${AWS_REGION}" \
  --task-definition "${ECS_TASK_FAMILY}" \
  --query 'taskDefinition' \
  --output json > "${task_def_json}"

jq --arg image "${IMAGE}" '
  del(
    .taskDefinitionArn,
    .revision,
    .status,
    .requiresAttributes,
    .compatibilities,
    .registeredAt,
    .registeredBy,
    .deregisteredAt
  )
  | .containerDefinitions[0].image = $image
' "${task_def_json}" > "${new_task_def_json}"

new_arn="$(
  aws ecs register-task-definition \
    --region "${AWS_REGION}" \
    --cli-input-json "file://${new_task_def_json}" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text
)"

echo "Registered ${new_arn}"

aws ecs update-service \
  --region "${AWS_REGION}" \
  --cluster "${ECS_CLUSTER}" \
  --service "${ECS_SERVICE}" \
  --task-definition "${new_arn}" \
  --force-new-deployment \
  >/dev/null

echo "Waiting for ECS service to stabilize (circuit breaker rollback if unhealthy)..."
if ! aws ecs wait services-stable \
  --region "${AWS_REGION}" \
  --cluster "${ECS_CLUSTER}" \
  --services "${ECS_SERVICE}"; then
  echo "::error::Service did not stabilize. Treat this as a failed deployment; ECS circuit breaker should have rolled back."
  aws ecs describe-services \
    --region "${AWS_REGION}" \
    --cluster "${ECS_CLUSTER}" \
    --services "${ECS_SERVICE}" \
    --query 'services[0].{status:status,running:runningCount,desired:desiredCount,events:events[:5],deployments:deployments}' \
    --output json
  exit 1
fi

echo "Checking ${HEALTH_URL}"
ok=0
for _ in 1 2 3 4 5 6; do
  if curl -fsS --max-time 10 "${HEALTH_URL}" | grep -q healthy; then
    ok=1
    break
  fi
  sleep 10
done

if [[ "${ok}" -ne 1 ]]; then
  echo "::error::Health check failed after a stable ECS service. Inspect target health and application logs."
  exit 1
fi

echo "Deployment healthy."
