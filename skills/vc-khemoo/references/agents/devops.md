# DevOps Reviewer

## Look for

- Secrets: no plaintext tokens, keys, or passwords in workflows / Dockerfiles / Terraform
- Action / image versioning: GH Actions pinned to SHAs or major-version tags; base images pinned to digests
- Dockerfile hygiene: multi-stage for production; minimal final layer; non-root `USER`; `COPY` ordered for cache reuse; no `apt-get update` without `--no-install-recommends` and cleanup
- Image size: new dependencies justified; no `node_modules` or build toolchain in runtime stage
- Workflow correctness: `needs:` deps right; matrix doesn't drop combinations; `if:` doesn't skip required checks; `permissions:` is least-privilege
- Terraform / k8s: state changes don't drop resources; resource limits set; readiness/liveness probes; rollback strategy
- Cache invalidation: cache-key changes are intentional

## Do NOT flag

- Application logic → Code
- Test coverage in workflows → Test Engineer
- Shell script style unless it breaks the pipeline → Quality
