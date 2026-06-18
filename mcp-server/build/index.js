#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { parse, MermaidParseError } from "@mermaid-js/parser";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
const execFileAsync = promisify(execFile);
// Map from the first keyword of a Mermaid diagram to the parser's type key.
// Types not listed here are not supported by @mermaid-js/parser and will return
// a "not supported" notice rather than a syntax error.
const KEYWORD_TO_TYPE = {
    info: "info",
    packet: "packet",
    pie: "pie",
    treeview: "treeView",
    "architecture-beta": "architecture",
    gitgraph: "gitGraph",
    eventmodeling: "eventmodeling",
    radar: "radar",
    treemap: "treemap",
    wardley: "wardley",
};
// Diagram types handled by the main mermaid renderer but not by @mermaid-js/parser.
// We report these as "unsupported for syntax checking" rather than failing silently.
const KNOWN_UNSUPPORTED = new Set([
    "flowchart",
    "graph",
    "sequencediagram",
    "classdiagram",
    "statediagram",
    "statediagram-v2",
    "erdiagram",
    "journey",
    "gantt",
    "requirementdiagram",
    "mindmap",
    "timeline",
    "block-beta",
    "xychart-beta",
    "sankey-beta",
    "quadrantchart",
    "zenuml",
]);
/** Extract the first meaningful keyword from a Mermaid diagram string. */
function detectDiagramKeyword(diagram) {
    for (const line of diagram.split("\n")) {
        const trimmed = line.trim().toLowerCase();
        if (trimmed.length === 0 || trimmed.startsWith("%%"))
            continue;
        // Take the first token on the first non-comment, non-empty line
        return trimmed.split(/\s/)[0];
    }
    return "";
}
const server = new McpServer({ name: "mcp-server", version: "0.1.0" });
server.registerTool("validate_mermaid", {
    description: "Run the Mermaid parser on a diagram string and return syntax validation results. " +
        "Pass the raw diagram content without the surrounding ``` fences. " +
        "Use this for hard syntax errors — not semantic review. " +
        "Returns JSON: { valid: boolean, errors?: [{message: string}], unsupported?: boolean, diagramType?: string }",
    inputSchema: z.object({
        diagram: z
            .string()
            .describe("The raw Mermaid diagram text (no fenced code block markers). Example: 'flowchart LR\\n  A --> B'"),
    }),
}, async ({ diagram }) => {
    const keyword = detectDiagramKeyword(diagram);
    const parserType = KEYWORD_TO_TYPE[keyword];
    // Unknown keyword — neither supported nor known-unsupported
    if (!parserType && !KNOWN_UNSUPPORTED.has(keyword)) {
        const result = JSON.stringify({
            valid: null,
            unsupported: true,
            diagramType: keyword || "unknown",
            message: `Diagram type "${keyword || "unknown"}" is not recognised. Cannot perform syntax validation.`,
        });
        return { content: [{ type: "text", text: result }] };
    }
    // Known unsupported type — not covered by @mermaid-js/parser
    if (!parserType) {
        const result = JSON.stringify({
            valid: null,
            unsupported: true,
            diagramType: keyword,
            message: `Diagram type "${keyword}" is not supported by the static parser. Syntax cannot be validated deterministically — apply LLM-based reasoning only.`,
        });
        return { content: [{ type: "text", text: result }] };
    }
    // Supported type — run the parser
    try {
        // Cast through `any` because the overloads use a string union — parserType is already
        // validated against KEYWORD_TO_TYPE so this is safe.
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        await parse(parserType, diagram);
        const result = JSON.stringify({ valid: true, diagramType: parserType });
        return { content: [{ type: "text", text: result }] };
    }
    catch (err) {
        if (err instanceof MermaidParseError) {
            const result = JSON.stringify({
                valid: false,
                diagramType: parserType,
                errors: [{ message: err.message }],
            });
            return { content: [{ type: "text", text: result }] };
        }
        // Unexpected error — surface it as isError
        return {
            content: [
                {
                    type: "text",
                    text: `Unexpected parser error: ${err instanceof Error ? err.message : String(err)}`,
                },
            ],
            isError: true,
        };
    }
});
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
        if (err && typeof err === "object" && "stdout" in err && "stderr" in err) {
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
    console.error("mcp-server running on stdio");
}
main().catch((error) => {
    console.error("Fatal error:", error);
    process.exit(1);
});
