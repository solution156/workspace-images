# Workspace Images

Repository cho các image minh họa (workspace/tooling images) + pipeline build-primary.

## Cấu trúc repo

- `.gitlab-ci.yml` — parent pipeline entry point
- `images/` — Dockerfile của từng image
- `images.json` — inventory ảnh (name, Dockerfile, tags, build args...)
- `shared/` — scripts/chunks dùng chung giữa các pipeline stage
- `out/` — chứa artifacts, catalog, scan, trace sau mỗi job

## Pipeline stages

1. `validate` (ci-tools)
2. `plan` (generate child)
3. `build` (docker build)
4. `scan` (trivy)
5. `patch` (harbor snapshot)
6. `verify` (runtime + trivy gate)
7. `sbom` (cyclonedx)
8. `evidence` (release.py)
9. `sign` (cosign)
10. `promote` (harbor promote)
11. `release` (publish)
12. `cleanup`

## Liên kết với ci-core

Pipeline này `include` template từ project `https://gitlab.com/hermes156/ci-core`,
file chính: `/templates/workspace-parent.yaml`
- `CI_CORE_PROJECT` = `hermes156/ci-core`
- `CI_CORE_REF`   = `v2.1.0`

## Build & Trigger

Các image sẽ được build và push lên Harbor registry theo `images.json`.
Pipeline cần các biến môi trường sau (đặt ở GitLab CI/CD settings):
- `HARBOR_REGISTRY`: registry host (vd: `rd-harbor-secops.servicemicro.net`)
- `HARBOR_PROJECT`: project trong Harbor (vd: `kubeworkspace`)
- `HARBOR_USER`, `HARBOR_PASSWORD`: credential cho Harbor
- `COSIGN_PRIVATE_KEY`, `COSIGN_PASSWORD`: bằng chứng digital signing

## How to run locally

```bash
docker build -t test-image .
docker run --rm -it test-image /bin/sh
```

## Notes

- Never use `latest` tag for production images.
- All generated artifacts under `out/` are ephemeral.
