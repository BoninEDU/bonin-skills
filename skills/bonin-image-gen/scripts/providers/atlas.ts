import type { CliArgs } from "../types";

const DEFAULT_MODEL = "openai/gpt-image-2/text-to-image";
const DEFAULT_BASE_URL = "https://api.atlascloud.ai/api/v1";
const DEFAULT_POLL_INTERVAL_MS = 2_000;
const DEFAULT_POLL_TIMEOUT_MS = 300_000;
const TERMINAL_FAILURES = new Set(["failed", "error", "cancelled", "canceled"]);

type AtlasPrediction = {
  id?: string;
  prediction_id?: string;
  status?: string;
  outputs?: string[];
  output?: string | string[];
  error?: string;
};

type AtlasResponse = AtlasPrediction & { data?: AtlasPrediction };

export function getDefaultModel(): string {
  return process.env.ATLASCLOUD_IMAGE_MODEL || DEFAULT_MODEL;
}

function getApiKey(): string {
  const key = process.env.ATLASCLOUD_API_KEY;
  if (!key) {
    throw new Error("ATLASCLOUD_API_KEY is required for the Atlas Cloud provider.");
  }
  return key;
}

function getBaseUrl(): string {
  return (process.env.ATLASCLOUD_GENERATION_API_BASE || DEFAULT_BASE_URL).replace(/\/+$/, "");
}

function unwrapResponse(payload: AtlasResponse): AtlasPrediction {
  return payload.data && typeof payload.data === "object" ? payload.data : payload;
}

function parsePositiveInt(value: string | undefined, fallback: number): number {
  const parsed = Number.parseInt(value || "", 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function parseAspectRatio(value: string | null): number {
  const match = value?.match(/^(\d+(?:\.\d+)?):(\d+(?:\.\d+)?)$/);
  if (!match) return 1;
  const width = Number.parseFloat(match[1]!);
  const height = Number.parseFloat(match[2]!);
  return width > 0 && height > 0 ? width / height : 1;
}

export function resolveSize(args: Pick<CliArgs, "size" | "aspectRatio" | "quality">): string {
  if (args.size) return args.size;

  const ratio = parseAspectRatio(args.aspectRatio);
  if (Math.abs(ratio - 1) < 0.1) {
    return args.quality === "normal" ? "1024x1024" : "2048x2048";
  }
  if (ratio > 1) {
    return args.quality === "normal" ? "1536x1024" : "2048x1152";
  }
  return args.quality === "normal" ? "1024x1536" : "1152x2048";
}

export function buildRequestBody(
  prompt: string,
  model: string,
  args: Pick<CliArgs, "size" | "aspectRatio" | "quality">
): Record<string, string> {
  return {
    model,
    prompt,
    size: resolveSize(args),
    quality: args.quality === "normal" ? "medium" : "high",
    output_format: "png",
  };
}

export function validateArgs(_model: string, args: CliArgs): void {
  if (args.referenceImages.length > 0) {
    throw new Error("Atlas Cloud text-to-image models do not support --ref in this provider.");
  }
  if (args.n !== 1) {
    throw new Error("Atlas Cloud generates exactly one image per request. Set --n 1 or omit --n.");
  }
  if (args.responseFormat === "url") {
    throw new Error("Atlas Cloud provider saves the generated image file and does not support --responseFormat url.");
  }
}

async function parseJsonResponse(res: Response, operation: string): Promise<AtlasResponse> {
  if (!res.ok) {
    const detail = (await res.text()).slice(0, 1_000);
    throw new Error(`Atlas Cloud ${operation} error (${res.status}): ${detail}`);
  }
  return (await res.json()) as AtlasResponse;
}

async function getPrediction(
  id: string,
  apiKey: string,
  baseUrl: string
): Promise<AtlasPrediction> {
  const res = await fetch(`${baseUrl}/model/result/${encodeURIComponent(id)}`, {
    headers: {
      Accept: "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
  });
  return unwrapResponse(await parseJsonResponse(res, "result"));
}

export async function pollPrediction(
  id: string,
  apiKey: string,
  baseUrl: string,
  sleep: (ms: number) => Promise<void> = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
): Promise<string> {
  const timeoutMs = parsePositiveInt(process.env.ATLASCLOUD_POLL_TIMEOUT_MS, DEFAULT_POLL_TIMEOUT_MS);
  const intervalMs = parsePositiveInt(process.env.ATLASCLOUD_POLL_INTERVAL_MS, DEFAULT_POLL_INTERVAL_MS);
  const deadline = Date.now() + timeoutMs;
  let delay = intervalMs;

  while (Date.now() < deadline) {
    const prediction = await getPrediction(id, apiKey, baseUrl);
    const status = (prediction.status || "").toLowerCase();
    if (["completed", "succeeded", "success"].includes(status)) {
      const outputs = prediction.outputs ?? (typeof prediction.output === "string" ? [prediction.output] : prediction.output) ?? [];
      const url = outputs[0];
      if (!url) throw new Error("Atlas Cloud completed without an output URL.");
      return url;
    }
    if (TERMINAL_FAILURES.has(status)) {
      throw new Error(`Atlas Cloud generation failed: ${prediction.error || status}`);
    }
    await sleep(delay);
    delay = Math.min(delay * 2, 10_000);
  }

  throw new Error(`Atlas Cloud generation timed out after ${timeoutMs}ms.`);
}

export async function generateImage(prompt: string, model: string, args: CliArgs): Promise<Uint8Array> {
  const apiKey = getApiKey();
  const baseUrl = getBaseUrl();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 120_000);

  let created: AtlasPrediction;
  try {
    const res = await fetch(`${baseUrl}/model/generateImage`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(buildRequestBody(prompt, model, args)),
      signal: controller.signal,
    });
    created = unwrapResponse(await parseJsonResponse(res, "generation"));
  } finally {
    clearTimeout(timeout);
  }

  const id = created.id || created.prediction_id;
  if (!id) throw new Error("Atlas Cloud response did not include a prediction id.");

  const outputUrl = await pollPrediction(id, apiKey, baseUrl);
  const parsedUrl = new URL(outputUrl);
  if (parsedUrl.protocol !== "https:") {
    throw new Error("Atlas Cloud returned a non-HTTPS output URL.");
  }
  const imageRes = await fetch(outputUrl);
  if (!imageRes.ok) {
    throw new Error(`Failed to download image from Atlas Cloud: ${imageRes.status}`);
  }
  return new Uint8Array(await imageRes.arrayBuffer());
}
