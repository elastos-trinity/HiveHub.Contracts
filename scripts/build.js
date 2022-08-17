import { run } from "hardhat";
import { basename } from "path";

import inputs from "../build-contracts.json";

async function main() {
  if (process.argv.length > 2) {
    inputs = process.argv.slice(2);
  }
  for (const file of inputs) {
    const files = [file];
    const output = `./dist/${basename(file)}`;
    await run("flatter", { files, output });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
