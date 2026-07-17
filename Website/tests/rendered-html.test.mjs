import assert from "node:assert/strict";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", String(Date.now()));
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("renders the TV Companion Kit product page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>TV Companion Kit/);
  assert.match(html, /The TV is the/);
  assert.match(html, /shared stage/);
  assert.match(html, /private console/);
  assert.match(html, /DeviceDiscoveryUI/);
  assert.match(html, /Network\.framework/);
  assert.match(html, /12<\/strong> tests passing/);
  assert.match(html, /aria-label="Primary navigation"/);
  assert.doesNotMatch(html, /codex-preview|SkeletonPreview|react-loading-skeleton/);
});
