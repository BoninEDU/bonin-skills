import assert from "node:assert/strict";
import test, { type TestContext } from "node:test";

import type { CliArgs } from "../types.ts";
import {
  buildRequestBody,
  generateImage,
  getDefaultModel,
  pollPrediction,
  resolveSize,
  validateArgs,
} from "./atlas.ts";

function makeArgs(overrides: Partial<CliArgs> = {}): CliArgs {
  return {
    prompt: null,
    promptFiles: [],
    imagePath: null,
    provider: "atlas",
    model: null,
    aspectRatio: null,
    size: null,
    quality: null,
    imageSize: null,
    imageApiDialect: null,
    referenceImages: [],
    n: 1,
    batchFile: null,
    jobs: null,
    json: false,
    help: false,
    responseFormat: null,
    ...overrides,
  };
}

function useEnv(t: TestContext, values: Record<string, string | null>): void {
  const previous = new Map<string, string | undefined>();
  for (const [key, value] of Object.entries(values)) {
    previous.set(key, process.env[key]);
    if (value == null) delete process.env[key];
    else process.env[key] = value;
  }
  t.after(() => {
    for (const [key, value] of previous) {
      if (value == null) delete process.env[key];
      else process.env[key] = value;
    }
  });
}

test("Atlas Cloud defaults to the current GPT Image 2 route", (t) => {
  useEnv(t, { ATLASCLOUD_IMAGE_MODEL: null });
  assert.equal(getDefaultModel(), "openai/gpt-image-2/text-to-image");
});

test("resolveSize maps quality and orientation to supported Atlas sizes", () => {
  assert.equal(resolveSize({ size: null, aspectRatio: null, quality: "normal" }), "1024x1024");
  assert.equal(resolveSize({ size: null, aspectRatio: "16:9", quality: "2k" }), "2048x1152");
  assert.equal(resolveSize({ size: null, aspectRatio: "3:4", quality: "2k" }), "1152x2048");
  assert.equal(resolveSize({ size: "1536x1024", aspectRatio: "1:1", quality: "2k" }), "1536x1024");
});

test("buildRequestBody uses the Atlas model schema", () => {
  assert.deepEqual(buildRequestBody("a cat", "openai/gpt-image-2/text-to-image", {
    size: null,
    aspectRatio: "16:9",
    quality: "2k",
  }), {
    model: "openai/gpt-image-2/text-to-image",
    prompt: "a cat",
    size: "2048x1152",
    quality: "high",
    output_format: "png",
  });
});

test("validateArgs rejects unsupported multi-image, URL, and reference modes", () => {
  assert.throws(() => validateArgs("model", makeArgs({ n: 2 })), /exactly one image/);
  assert.throws(() => validateArgs("model", makeArgs({ responseFormat: "url" })), /does not support/);
  assert.throws(() => validateArgs("model", makeArgs({ referenceImages: ["ref.png"] })), /do not support --ref/);
});

test("pollPrediction uses bounded GET polling and returns the first output", async (t) => {
  useEnv(t, { ATLASCLOUD_POLL_TIMEOUT_MS: "1000", ATLASCLOUD_POLL_INTERVAL_MS: "1" });
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  const responses = [
    { data: { status: "processing" } },
    { data: { status: "completed", outputs: ["https://example.com/result.png"] } },
  ];
  globalThis.fetch = async () => new Response(JSON.stringify(responses.shift()), { status: 200 });
  const sleeps: number[] = [];
  const url = await pollPrediction("prediction/id", "key", "https://api.example.test", async (ms) => { sleeps.push(ms); });
  assert.equal(url, "https://example.com/result.png");
  assert.deepEqual(sleeps, [1]);
});

test("generateImage performs one POST, polls with GET, and downloads HTTPS output", async (t) => {
  useEnv(t, {
    ATLASCLOUD_API_KEY: "test-key",
    ATLASCLOUD_GENERATION_API_BASE: "https://api.example.test/api/v1",
    ATLASCLOUD_POLL_INTERVAL_MS: "1",
    ATLASCLOUD_POLL_TIMEOUT_MS: "1000",
  });
  const originalFetch = globalThis.fetch;
  t.after(() => { globalThis.fetch = originalFetch; });
  const methods: string[] = [];
  globalThis.fetch = async (input, init) => {
    const url = String(input);
    methods.push(init?.method || "GET");
    if (url.endsWith("/model/generateImage")) {
      return new Response(JSON.stringify({ data: { id: "prediction-id" } }), { status: 200 });
    }
    if (url.includes("/model/result/")) {
      return new Response(JSON.stringify({ data: { status: "completed", outputs: ["https://cdn.example.test/image.png"] } }), { status: 200 });
    }
    return new Response(Uint8Array.from([1, 2, 3]), { status: 200 });
  };
  const image = await generateImage("a cat", "openai/gpt-image-2/text-to-image", makeArgs());
  assert.deepEqual([...image], [1, 2, 3]);
  assert.deepEqual(methods, ["POST", "GET", "GET"]);
});
