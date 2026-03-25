# GitHub build provenance + Kyverno

GitHub Actions builds a container image, attaches **SLSA build provenance** ([artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-build-provenance-for-container-images)), and pushes to GHCR. **Kyverno** can enforce that only images with provenance from this repo’s workflow are admitted.

Workflow: `.github/workflows/action.yml` (job **CI**). Image: `ghcr.io/<org>/pov-github-attestations-sbom:github-attestation`.

## Trigger CI

| Action | Effect |
|--------|--------|
| **Push** to any branch | Runs **CI** on that push. |
| **Open or update a PR** | Runs **CI** for the PR (same workflow; `pull_request`). |
| **Merge to default branch** | Runs **CI** on the merge commit. |

Check **Actions** → **CI** for status. When it’s green, the attested image tag above should exist on GHCR.

**Verify locally (optional):**

```bash
docker login ghcr.io
gh attestation verify oci://ghcr.io/<org>/pov-github-attestations-sbom:github-attestation \
  -R <org>/pov-attestation-test \
  --predicate-type https://slsa.dev/provenance/v1
```

Replace `<org>` with your GitHub org or user (e.g. `nirmata`).

## Deploy the policy (Kyverno 1.17+)

```bash
kubectl apply -f sample-policies/verify-github-provenance.yaml
```

The policy matches `ghcr.io/<org>/*` and expects provenance signed by **this** repo’s `action.yml` workflow. Adjust `subjectRegExp` in that file if your org or repo name differs.

## Test admission

**Allowed** (image built by this repo’s CI):

```bash
kubectl run ok --image=ghcr.io/<org>/pov-github-attestations-sbom:github-attestation \
  --restart=Never -- /bin/sh -c "sleep 600"
```

**Denied** (different workflow / not trusted identity), example:

```bash
kubectl run bad --image=ghcr.io/<org>/kubectl:1.35.0 --restart=Never -- sleep 600
```

Or apply the samples:

```bash
kubectl apply -f sample-resources/pod-attested-github.yaml      # expect created
kubectl apply -f sample-resources/pod-unattested-github.yaml     # expect denied
kubectl delete pod test-attested-github test-unattested-github --ignore-not-found
```

## Reference

- [Kyverno ImageValidatingPolicy](https://kyverno.io/docs/policy-types/image-validating-policy/)
