/**
 * Build script for Chrome Extension using Deno.
 * Requirements: 'zip' utility installed on the system.
 */

const EXT_DIR = "./";
const DIST_DIR = "./dist";
const ZIP_FILE = `${DIST_DIR}/extension.zip`;
const CRX_FILE = `${DIST_DIR}/extension.crx`;
const KEY_FILE = "./private_key.pem";

async function build() {
  console.log("🚀 Starting build...");

  // 1. Prepare dist directory
  try { await Deno.remove(DIST_DIR, { recursive: true }); } catch {}
  await Deno.mkdir(DIST_DIR, { recursive: true });

  // 2. Create Zip (Using system zip for simplicity)
  console.log("📦 Zipping extension...");
  const files = ["manifest.json", "background.js", "options.html", "options.js"];
  const zipProcess = new Deno.Command("zip", {
    args: [ZIP_FILE, ...files],
  });
  await zipProcess.output();

  // 3. Generate private key if it doesn't exist (using openssl)
  if (!await exists(KEY_FILE)) {
    console.log("🔑 Generating private key...");
    const keyGen = new Deno.Command("openssl", {
      args: ["genrsa", "-out", KEY_FILE, "2048"],
    });
    await keyGen.output();
  }

  // 4. Create CRX (CRX3 format signature)
  // Note: For full CRX3 binary packaging in pure JS/TS, a protobuf implementation is required.
  // As a streamlined alternative for custom tools, we use openssl to sign.
  console.log("✍️  Signing package...");
  
  // Simplified: In a real world scenario, you'd use a tool like 'crx3' 
  // or a Deno port of it. Since we want to avoid Chrome browser:
  const signProcess = new Deno.Command("openssl", {
    args: ["dgst", "-sha256", "-sign", KEY_FILE, ZIP_FILE],
  });
  const { stdout: signature } = await signProcess.output();
  
  console.log(`✅ Build complete: ${ZIP_FILE}`);
  console.log(`💡 To create a valid .crx binary, use a CRX3 utility with the generated ${KEY_FILE}`);
}

async function exists(path: string): Promise<boolean> {
  try {
    await Deno.stat(path);
    return true;
  } catch { return false; }
}

build();