# Open Watch Graph (OWG)

## Product thesis

Cinema should contribute an open interoperability standard, not only ship another streaming interface.

**Open Watch Graph (OWG)** is a proposed, machine-readable registry format for answering a hard question: *where is this title authorized to be watched, by whom, in which territory, through which method, and until when?*

The format is described in [the v1 JSON Schema](../schemas/watch-source-manifest.v1.schema.json). The example in [examples/](../examples/watch-source-manifest.pending.example.json) is intentionally fictional and marked pending review. It is not a playable source.

## What makes OWG useful

A source entry carries structured information that ordinary watch links omit:

- Stable title and provider identifiers.
- Rights holder, evidence reference, and license reference.
- Exact territories and validity window.
- Explicit allowed methods (official embed, direct playback, download, cache).
- Allowed destination hosts, plus subtitle/audio and accessibility metadata.
- Review state and an optional Ed25519 maintainer signature.

This makes a manifest portable across clients and services. A developer could use the registry to display availability without implementing a private, undocumented scraper for each provider.

## Security model

A JSON Schema-valid manifest is **not automatically authorized**. A production service must also:
1. Verify the manifest signature against a trusted key registry.
2. Require an approved review state and active rights grant.
3. Compare the viewer's territory against the explicit allowlist.
4. Verify the requested playback method.
5. Enforce the provider's hostname allowlist, including redirect and nested playlist rules.
6. Fail closed when evidence is missing, expired, disputed, or ambiguous.

No provider JavaScript is executed. No generic URL fetch proxy is exposed. Provider-specific code remains reviewed, versioned, and removable.

## Governance proposal

The format should be community-reviewed and versioned independently from app releases. Changes require a schema proposal, compatibility notes, security review, and sample fixtures. Public submissions enter a pending queue; maintainers approve them only after verifying actual rights evidence and provider terms.

The first version is deliberately small. Do not add a field unless a real client or rights review workflow needs it.

## Success criteria

- A third-party developer can validate a manifest without using Cinema's app.
- A client can show "not available here" rather than guessing.
- A provider can revoke or narrow a grant without shipping a client update.
- Every approval is attributable and auditable.
- No title becomes playable solely because a URL is reachable.
