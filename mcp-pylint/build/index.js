#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
const execFileAsync = promisify(execFile);
const server = new McpServer({ name: "mcp-pylint", version: "0.1.0" });
server.registerTool("pylint_check", {
    description: "Run pylint on a Python file and return findings. Installs pylint automatically if not present.",
    inputSchema: z.object({
        file_path: z
            .string()
            .describe("Absolute or workspace-relative path to the Python file to lint"),
    }),
}, async ({ file_path }) => {
    // Ensure pylint is installed
    try {
        await execFileAsync("python3", ["-m", "pylint", "--version"]);
    }
    catch {
        try {
            await execFileAsync("python3", ["-m", "pip", "install", "--quiet", "pylint"]);
        }
        catch (installErr) {
            return {
                content: [
                    {
                        type: "text",
                        text: `Failed to install pylint: ${installErr instanceof Error ? installErr.message : String(installErr)}`,
                    },
                ],
                isError: true,
            };
        }
    }
    // Run pylint
    let stdout = "";
    let stderr = "";
    try {
        const result = await execFileAsync("python3", [
            "-m",
            "pylint",
            "--output-format=text",
            file_path,
        ]);
        stdout = result.stdout;
        stderr = result.stderr;
    }
    catch (err) {
        // pylint exits non-zero when it finds issues — that is expected behaviour
        if (err && typeof err === "object" && "stdout" in err) {
            stdout = err.stdout ?? "";
            stderr = err.stderr ?? "";
        }
        else {
            return {
                content: [
                    {
                        type: "text",
                        text: `pylint execution error: ${err instanceof Error ? err.message : String(err)}`,
                    },
                ],
                isError: true,
            };
        }
    }
    const output = [stdout, stderr].filter(Boolean).join("\n").trim();
    return {
        content: [{ type: "text", text: output || "pylint produced no output." }],
    };
});
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("mcp-pylint running on stdio");
}
main().catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
});
