# KubeWorkspace — Workspace Images

Source Dockerfiles/installer cho Kasm workspace images. Mỗi image có version riêng trong `images.json`; version này không phải version CI Core hay version browser/Kasm.

## Kiến trúc

`.gitlab-ci.yml` include **CI Core v2.1.0** `/templates/workspace-parent.yaml`.
Parent validate source, sinh `generated-child.yml` và trigger child cùng project/commit.
Core chứa logic chung; repo này chỉ chứa catalog, source và event workflow.

**Trước khi push consumer:** phải publish core tag mới có file mới. Không ghi đè core tag `v2.0.0` đang dùng ở môi trường khác. Include ref và `CI_CORE_REF` phải luôn khớp.

## Hành vi

- MR, feature/bugfix/hotfix: FAST, chỉ image bị ảnh hưởng diff, build/runtime smoke **không push**.
- Protected main: FULL, **tất cả enabled images**, tag `main` sau gates.
- Protected release branch `release/<image>/vX.Y.Z`: chỉ image đó, tag `rc-X.Y.Z`.
- Protected Git tag `<image>/vX.Y.Z` hoặc `release/<image>/vX.Y.Z`: chỉ image đó, tag immutable `X.Y.Z` + GitLab Release.
- Nếu cần chọn image thủ công: Run pipeline trên development branch/protected main, `IMAGE_SELECTION=chrome` hoặc `chrome,firefox` hoặc `all`. Push/MR phải để `auto`.
- FAST initial commit không có diff base: báo no-changes, không tự phát hành tất cả. MR hoặc manual selection để test rõ ràng.

FULL DAG: build → scan → patch → verify Trivy/runtime → SBOM → evidence → sign → promote → release (tag only).
Mỗi image độc lập, artifact nằm `out/<id>/`; candidate/patched digests được khóa và kiểm tra, không rebuild khi promote.

## Bật VS Code đúng quy trình

1. `images.json` khai báo `extension_lock` và `runtime_check` cho VS Code.
2. Run pipeline trên development branch với `EXTENSION_BOOTSTRAP=vscode`, giữ `IMAGE_SELECTION=auto`.
3. Tải artifact `out/vscode/extensions.lock` từ job `lock:vscode`.
4. Review/commit lock thật vào `images/vscode/configs/extensions.lock`, rồi đổi `enabled:true`.
5. Chạy FAST/MR trước protected main. Không cần cài VS Code trên host.

Normal validation require lock khớp toàn bộ manifest, không chỉ kiểm tra file có chữ. Không dùng version giả hoặc bỏ gate để xanh.

## Mở rộng

Thêm `images/<id>/Dockerfile` + row vào catalog: `id`, `repository`, `version`, `enabled`, `context`, `dockerfile`, `platform`, `depends_on`. Hiện hỗ trợ `context=.` và `linux/amd64`.

- Tài nguyên shared phải khai báo dependency; một shared change chỉ chọn image phụ thuộc trong FAST.
- Optional `runtime_check` là script reviewed trong repo, stream vào container qua stdin.
- Optional `extension_lock` cho image cần bootstrap extension; không hardcode tên image trong core.
- Dockerfiles cuối cùng USER1000, source COPY phải tồn tại trong context.
- `.dockerignore` loại `.ci-tools`, `.docker-job`, reports/out và Git metadata khỏi build context.

## Môi trường và quyền

Core runbook: `ci-core/docs/PIPELINE_GUIDE_VI.md` trong repo CI Core.
Cần GitLab job-token allowlist, protected main/release refs, robot Harbor và Cosign secrets cho FULL/RELEASE; FAST chỉ cần pull-only nếu base private. DOCKER_AUTH_CONFIG là JSON để Runner pull private job images. Không tự tạo lại CI_SERVER_URL/CI_JOB_TOKEN.

Local tests không cần GitLab; exact workspace builds cần reachable registry/mirror, mạng download installers, CA/proxy. Khi host không resolve Harbor nội bộ thì không thể kết luận Chrome build exact đã pass. GUI/VNC/UAT phải test ở hạ tầng Kasm thật.

## Build ngoài CI

Context luôn là repo root:

```bash
docker buildx build --load --pull --platform linux/amd64 \
  -f images/chrome/Dockerfile -t local/sdwf-chrome:dev .
```

Chạy smoke cơ bản không thay thế UAT. Không prune daemon dùng chung hoặc lưu credential vào image/artifacts.
