import { readFileSync, readdirSync } from "node:fs";
import { join, relative } from "node:path";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";

const schemaPath = "../../../schemas/watch-source-manifest.v1.schema.json";
const examplesPath = "../../../examples";
const schema = JSON.parse(readFileSync(new URL(schemaPath, import.meta.url), "utf8"));
const ajv = new Ajv2020({ allErrors: true, strict: true });
addFormats(ajv);

const validate = ajv.compile(schema);

function collectJSON(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return collectJSON(path);
    return entry.isFile() && entry.name.endsWith(".json") ? [path] : [];
  });
}

const files = collectJSON(examplesPath);
if (files.length === 0) {
  throw new Error("No JSON manifest examples found.");
}

let failed = false;
for (const file of files) {
  const manifest = JSON.parse(readFileSync(file, "utf8"));
  if (!validate(manifest)) {
    failed = true;
    process.stderr.write(`Invalid manifest: ${relative(process.cwd(), file)}\n`);
    for (const error of validate.errors ?? []) {
      process.stderr.write(`  - ${error.instancePath || "/"}: ${error.message}\n`);
    }
  } else {
    process.stdout.write(`Valid manifest: ${relative(process.cwd(), file)}\n`);
  }
}

if (failed) process.exitCode = 1;
else process.stdout.write(`Validated ${files.length} manifest example(s).\n`);
