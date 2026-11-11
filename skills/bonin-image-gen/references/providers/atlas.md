# Atlas Cloud (`--provider atlas`)

Read when the user explicitly selects `--provider atlas` or sets `default_provider: atlas`.

## Setup

```bash
export ATLASCLOUD_API_KEY="..."
bun scripts/main.ts --provider atlas --prompt "A red apple on a white plate" --image apple.png
```

The built-in model is `openai/gpt-image-2/text-to-image`. Override it with `--model`,
`default_model.atlas`, or `ATLASCLOUD_IMAGE_MODEL`. The provider is never auto-selected,
so adding `ATLASCLOUD_API_KEY` does not change existing routing.

## Request Flow

1. Submit exactly one `POST /api/v1/model/generateImage` request. Generation POSTs are never retried because they may be billable.
2. Poll `GET /api/v1/model/result/{request_id}` with bounded exponential backoff until the prediction completes or fails.
3. Require an HTTPS output URL, download it, and save the image to `--image`.

The provider supports text-to-image only, one image per request, and file output. It rejects
`--ref`, `--n` values other than `1`, and `--response-format url` before submission.

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `ATLASCLOUD_API_KEY` | required | Bearer credential |
| `ATLASCLOUD_IMAGE_MODEL` | `openai/gpt-image-2/text-to-image` | Model route |
| `ATLASCLOUD_GENERATION_API_BASE` | `https://api.atlascloud.ai/api/v1` | Generation API base URL |
| `ATLASCLOUD_POLL_INTERVAL_MS` | `2000` | Initial result polling delay |
| `ATLASCLOUD_POLL_TIMEOUT_MS` | `300000` | Overall result polling timeout |

Batch mode limits Atlas to one active request. Each batch task still represents a separate paid
generation POST, so choose the task count deliberately.
