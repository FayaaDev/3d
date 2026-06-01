import http from "node:http";
import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import {
  createOpencodeClient,
  createOpencodeServer,
} from "../.opencode/node_modules/@opencode-ai/sdk/dist/index.js";

const __filename = fileURLToPath(import.meta.url);
const webRoot = path.dirname(__filename);
const repoRoot = path.resolve(webRoot, "..");
const publicDir = path.join(webRoot, "public");
const uploadsDir = path.join(webRoot, "uploads");
const exportsDir = path.join(repoRoot, "exports");
const cadViewerScriptDir = path.join(repoRoot, ".agents", "skills", "cad-viewer", "scripts", "viewer");
const cadViewerHost = "127.0.0.1";
const cadViewerStartPort = 4178;
const port = Number(process.env.PORT || 4317);
const opencodeHost = process.env.OPENCODE_HOST || "127.0.0.1";
const opencodePort = Number(process.env.OPENCODE_PORT || 4096);

const commandByPathway = {
  artwork: "artwork",
  technicaldrawing: "technicaldrawing",
};

const stageOrderByPathway = {
  artwork: [
    "upload",
    "choice",
    "magicimage",
    "potrace",
    "svg_cleanup",
    "openscad_build",
    "validate",
    "preview",
    "stl_export",
    "cad_viewer",
  ],
  technicaldrawing: [
    "upload",
    "choice",
    "openscad_build",
    "validate",
    "preview",
    "stl_export",
    "cad_viewer",
  ],
};

const stageLabels = {
  upload: "Upload",
  choice: "Choice",
  magicimage: "Image Cleanup",
  potrace: "Vector Trace",
  svg_cleanup: "SVG Cleanup",
  openscad_build: "OpenSCAD Build",
  validate: "Validate",
  preview: "Preview",
  stl_export: "STL Export",
  cad_viewer: "CAD Viewer",
};

const staticFiles = {
  "/": { file: path.join(publicDir, "index.html"), type: "text/html; charset=utf-8" },
  "/styles.css": { file: path.join(publicDir, "styles.css"), type: "text/css; charset=utf-8" },
  "/app.js": { file: path.join(publicDir, "app.js"), type: "text/javascript; charset=utf-8" },
};

const terminalStatuses = new Set(["completed", "failed"]);
const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
const artworkSubagentStageByType = {
  "imagemagick-png-inspector": "magicimage",
  "potrace-vectorizer": "potrace",
  "inkscape-svg-cleaner": "svg_cleanup",
};

const jobs = new Map();
let activeJobId = null;
let opencodeRuntimePromise = null;

ensureLocalOpencodePath();
await fs.mkdir(uploadsDir, { recursive: true });

function ensureLocalOpencodePath() {
  const localBinDir = path.join(os.homedir(), ".opencode", "bin");
  const currentPath = process.env.PATH ?? "";

  if (!currentPath.split(path.delimiter).includes(localBinDir)) {
    process.env.PATH = `${localBinDir}${path.delimiter}${currentPath}`;
  }
}

function createStages(pathway) {
  return stageOrderByPathway[pathway].map((key) => ({
    key,
    label: stageLabels[key],
    status: "pending",
  }));
}

function createJob({ fileName, pathway, storedFilePath }) {
  const jobId = randomUUID();
  const stages = createStages(pathway);

  for (const stage of stages) {
    if (stage.key === "upload" || stage.key === "choice") {
      stage.status = "completed";
    }
  }

  return {
    id: jobId,
    sessionId: null,
    commandName: commandByPathway[pathway],
    fileName,
    pathway,
    storedFilePath,
    status: "starting",
    statusLine: "Saved the file locally. Starting OpenCode.",
    cadViewerUrl: null,
    error: null,
    stages,
    currentStageKey: null,
    commandStarted: false,
    finalizing: false,
    knownSessionIds: new Set(),
    clients: new Set(),
    lastSnapshot: "",
    eventAbortController: null,
  };
}

function snapshotJob(job) {
  return {
    jobId: job.id,
    sessionId: job.sessionId,
    fileName: job.fileName,
    pathway: job.pathway,
    status: job.status,
    statusLine: job.statusLine,
    cadViewerUrl: job.cadViewerUrl,
    error: job.error,
    stages: job.stages,
  };
}

function emitJob(job) {
  const payload = JSON.stringify(snapshotJob(job));

  if (payload === job.lastSnapshot) {
    return;
  }

  job.lastSnapshot = payload;

  for (const client of [...job.clients]) {
    if (client.destroyed || client.writableEnded) {
      job.clients.delete(client);
      continue;
    }

    client.write(`data: ${payload}\n\n`);
  }
}

function getStage(job, key) {
  return job.stages.find((stage) => stage.key === key) ?? null;
}

function setStageActive(job, key, statusLine) {
  const nextIndex = job.stages.findIndex((stage) => stage.key === key);

  if (nextIndex === -1) {
    return;
  }

  for (let index = 0; index < nextIndex; index += 1) {
    if (job.stages[index].status === "pending" || job.stages[index].status === "active") {
      job.stages[index].status = "completed";
    }
  }

  const nextStage = job.stages[nextIndex];

  if (nextStage.status !== "completed") {
    nextStage.status = "active";
  }

  job.currentStageKey = key;
  job.status = terminalStatuses.has(job.status) ? job.status : "running";

  if (statusLine) {
    job.statusLine = statusLine;
  }

  emitJob(job);
}

function completeStage(job, key, statusLine) {
  const stage = getStage(job, key);

  if (!stage) {
    return;
  }

  stage.status = "completed";

  if (job.currentStageKey === key) {
    job.currentStageKey = null;
  }

  if (statusLine) {
    job.statusLine = statusLine;
  }

  emitJob(job);
}

function failJob(job, message, stageKey = job.currentStageKey ?? "cad_viewer") {
  if (isTransientFetchError(message)) {
    job.statusLine = "Transient fetch issue reported by OpenCode. Continuing to monitor the run.";
    emitJob(job);
    return;
  }

  if (job.status === "failed") {
    return;
  }

  const stage = getStage(job, stageKey);

  if (stage) {
    stage.status = "failed";
  }

  job.status = "failed";
  job.error = message;
  job.statusLine = message;
  job.currentStageKey = stageKey;

  if (job.eventAbortController && !job.eventAbortController.signal.aborted) {
    job.eventAbortController.abort();
  }

  emitJob(job);
}

function completeJob(job, viewerUrl) {
  if (!viewerUrl) {
    failJob(job, "Run finished without a valid CAD Viewer link.", "cad_viewer");
    return;
  }

  job.cadViewerUrl = viewerUrl;
  setStageActive(job, "stl_export", "STL export completed.");
  completeStage(job, "stl_export", "STL export completed.");
  setStageActive(job, "cad_viewer", "CAD Viewer handoff detected.");
  completeStage(job, "cad_viewer", "CAD Viewer handoff ready.");
  job.status = "completed";
  job.error = null;

  if (job.eventAbortController && !job.eventAbortController.signal.aborted) {
    job.eventAbortController.abort();
  }

  emitJob(job);
}

function activeJob() {
  return activeJobId ? jobs.get(activeJobId) ?? null : null;
}

function isJobRunning() {
  const job = activeJob();
  return Boolean(job && !terminalStatuses.has(job.status));
}

function sanitizeBaseName(fileName) {
  const stem = path.basename(fileName, path.extname(fileName));
  const safeStem = stem
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

  return safeStem || "upload";
}

function buildStoredFileName(originalFileName) {
  const stamp = new Date().toISOString().replace(/[.:]/g, "-");
  return `${stamp}-${sanitizeBaseName(originalFileName)}.png`;
}

function isPngBuffer(buffer) {
  if (buffer.byteLength < pngSignature.length) {
    return false;
  }

  return pngSignature.every((value, index) => buffer[index] === value);
}

function normalizeError(error) {
  if (error instanceof Error && error.message) {
    return error.message;
  }

  if (typeof error === "string") {
    return error;
  }

  return "Unexpected OpenCode failure.";
}

function isTransientFetchError(error) {
  return normalizeError(error).toLowerCase() === "fetch failed";
}

async function parseFormData(req, pathname) {
  const headers = new Headers();

  for (const [key, value] of Object.entries(req.headers)) {
    if (Array.isArray(value)) {
      headers.set(key, value.join(", "));
      continue;
    }

    if (typeof value === "string") {
      headers.set(key, value);
    }
  }

  const request = new Request(new URL(pathname, "http://127.0.0.1"), {
    method: req.method,
    headers,
    body: req,
    duplex: "half",
  });

  return request.formData();
}

async function getOpencodeRuntime() {
  if (!opencodeRuntimePromise) {
    opencodeRuntimePromise = (async () => {
      const existingBaseUrl = `http://${opencodeHost}:${opencodePort}`;

      try {
        const server = await createOpencodeServer({
          hostname: opencodeHost,
          port: opencodePort,
        });
        const client = createOpencodeClient({
          baseUrl: server.url,
          directory: repoRoot,
        });

        return { server, client };
      } catch (error) {
        const client = createOpencodeClient({
          baseUrl: existingBaseUrl,
          directory: repoRoot,
        });

        await client.command.list();
        return { server: null, client };
      }
    })().catch((error) => {
      opencodeRuntimePromise = null;
      throw error;
    });
  }

  return opencodeRuntimePromise;
}

function extractCadViewerUrl(text) {
  if (!text) {
    return null;
  }

  const matches = text.match(/https?:\/\/(?:127\.0\.0\.1|localhost):\d+\/\?[^\s"'<>]+/g) ?? [];

  for (const candidate of matches) {
    try {
      const parsed = new URL(candidate);
      const dir = parsed.searchParams.get("dir");

      if (dir && path.isAbsolute(dir)) {
        return candidate;
      }
    } catch {
      // Ignore malformed links and keep scanning.
    }
  }

  return null;
}

function collectTextFromParts(parts) {
  const values = [];

  for (const part of parts) {
    if (part.type === "text") {
      values.push(part.text);
    }

    if (part.type === "tool") {
      if (typeof part.state.output === "string") {
        values.push(part.state.output);
      }

      if (typeof part.state.raw === "string") {
        values.push(part.state.raw);
      }
    }
  }

  return values.join("\n");
}

async function findCadViewerUrlInSession(job, client) {
  const response = await client.session.messages({
    path: { id: job.sessionId },
  });

  const messages = [...response.data].reverse();

  for (const message of messages) {
    if (message.info.role !== "assistant") {
      continue;
    }

    const viewerUrl = extractCadViewerUrl(collectTextFromParts(message.parts));

    if (viewerUrl) {
      return viewerUrl;
    }
  }

  return null;
}

function eventSessionId(event) {
  if (!event?.properties) {
    return null;
  }

  return (
    event.properties.sessionID ??
    event.properties.info?.sessionID ??
    event.properties.part?.sessionID ??
    null
  );
}

function jobTracksSession(job, sessionId) {
  return Boolean(sessionId && job.knownSessionIds.has(sessionId));
}

function trackSession(job, sessionId) {
  if (sessionId) {
    job.knownSessionIds.add(sessionId);
  }
}

function matchArtworkStageFromTaskTool(part) {
  if (part.tool !== "task") {
    return null;
  }

  return artworkSubagentStageByType[part.state.input?.subagent_type] ?? null;
}

function matchLateStageFromBashTool(part) {
  if (part.tool !== "bash") {
    return null;
  }

  const command = String(part.state.input?.command ?? "").toLowerCase();

  if (command.includes("validate.sh")) {
    return "validate";
  }

  if (command.includes("multi-preview.sh") || command.includes("preview.sh")) {
    return "preview";
  }

  if (command.includes("export-stl.sh")) {
    return "stl_export";
  }

  return null;
}

function buildAutomaticQuestionAnswers(questionRequest) {
  return questionRequest.questions.map((question) => {
    const recommendedOption = question.options.find((option) => option.label.includes("(Recommended)"));
    const fallbackOption = question.options[0] ?? null;
    const selectedOption = recommendedOption ?? fallbackOption;

    return selectedOption ? [selectedOption.label] : [];
  });
}

async function autoApprovePermission(client, job, permission) {
  const permissionLabel = permission.permission ?? permission.tool ?? permission.id;
  job.statusLine = `Approving runtime permission: ${permissionLabel}.`;
  emitJob(job);

  await client.postSessionIdPermissionsPermissionId({
    path: {
      id: permission.sessionID,
      permissionID: permission.id,
    },
    body: {
      response: "once",
    },
  });
}

async function autoReplyToQuestion(client, job, questionRequest) {
  const questionLabel = questionRequest.questions[0]?.header ?? "workflow prompt";
  const answers = buildAutomaticQuestionAnswers(questionRequest);

  if (answers.some((answer) => answer.length === 0)) {
    failJob(job, `Run requires manual input for ${questionLabel}.`, job.currentStageKey ?? "openscad_build");
    return;
  }

  job.statusLine = `Answering workflow question: ${questionLabel}.`;
  emitJob(job);

  await client.question.reply({
    requestID: questionRequest.id,
    answers,
  });
}

async function collectExportedStlFiles(directory) {
  let entries;

  try {
    entries = await fs.readdir(directory, { withFileTypes: true });
  } catch {
    return [];
  }

  const files = [];

  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      files.push(...(await collectExportedStlFiles(entryPath)));
      continue;
    }

    if (entry.isFile() && entry.name.toLowerCase().endsWith(".stl")) {
      files.push(entryPath);
    }
  }

  return files;
}

function choosePrimaryStlFile(files) {
  if (files.length === 0) {
    return null;
  }

  return (
    files.find((filePath) => path.basename(filePath).toLowerCase().includes("plaque")) ??
    files.find((filePath) => path.basename(filePath).toLowerCase().includes("all")) ??
    files[0]
  );
}

async function probeCadViewerServer(portNumber) {
  try {
    const response = await fetch(`http://${cadViewerHost}:${portNumber}/__cad/server`, {
      signal: AbortSignal.timeout(1500),
    });

    if (!response.ok) {
      return null;
    }

    const payload = await response.json();

    if (
      payload?.app === "cad-viewer" &&
      payload?.dynamicRoot === true &&
      Number(payload?.serverApiVersion ?? 0) >= 2
    ) {
      return `http://${cadViewerHost}:${portNumber}`;
    }
  } catch {
    return null;
  }

  return false;
}

async function ensureCadViewerBaseUrl() {
  for (let portNumber = cadViewerStartPort; portNumber < cadViewerStartPort + 10; portNumber += 1) {
    const existingBaseUrl = await probeCadViewerServer(portNumber);

    if (typeof existingBaseUrl === "string") {
      return existingBaseUrl;
    }

    if (existingBaseUrl === false) {
      continue;
    }

    const child = spawn(
      "npm",
      [
        "--prefix",
        cadViewerScriptDir,
        "run",
        "start",
        "--",
        "--host",
        cadViewerHost,
        "--port",
        String(portNumber),
        "--shutdown-after",
        "12h",
      ],
      {
        cwd: repoRoot,
        detached: true,
        stdio: "ignore",
      },
    );

    child.unref();

    for (let attempt = 0; attempt < 20; attempt += 1) {
      await new Promise((resolve) => setTimeout(resolve, 500));
      const startedBaseUrl = await probeCadViewerServer(portNumber);

      if (typeof startedBaseUrl === "string") {
        return startedBaseUrl;
      }
    }
  }

  return null;
}

async function createFallbackCadViewerUrl() {
  const stlFiles = await collectExportedStlFiles(exportsDir);
  const primaryStlFile = choosePrimaryStlFile(stlFiles);

  if (!primaryStlFile) {
    return null;
  }

  const baseUrl = await ensureCadViewerBaseUrl();

  if (!baseUrl) {
    return null;
  }

  return `${baseUrl}/?dir=${encodeURIComponent(exportsDir)}&file=${encodeURIComponent(primaryStlFile)}`;
}

async function finalizeJob(job, client) {
  if (job.finalizing || terminalStatuses.has(job.status) || !job.commandStarted) {
    return;
  }

  job.finalizing = true;

  try {
    job.statusLine = "Session finished. Checking the final CAD Viewer handoff.";
    emitJob(job);

    const viewerUrl =
      job.cadViewerUrl ??
      (await findCadViewerUrlInSession(job, client)) ??
      (await createFallbackCadViewerUrl());

    if (!viewerUrl) {
      setStageActive(job, "cad_viewer", "The run finished without a CAD Viewer handoff.");
      failJob(job, "Run finished without a valid CAD Viewer link.", "cad_viewer");
      return;
    }

    completeJob(job, viewerUrl);
  } catch (error) {
    failJob(job, `Failed to inspect final session output: ${normalizeError(error)}`, "cad_viewer");
  } finally {
    job.finalizing = false;
  }
}

function applyToolStage(job, stageKey, part) {
  if (!stageKey) {
    return;
  }

  const title = part.state.title || `Running ${stageLabels[stageKey]}.`;

  if (part.state.status === "error") {
    if (isTransientFetchError(part.state.error)) {
      setStageActive(job, stageKey, `Transient fetch issue during ${stageLabels[stageKey]}. Continuing.`);
      return;
    }

    failJob(job, part.state.error || `Failed during ${stageLabels[stageKey]}.`, stageKey);
    return;
  }

  setStageActive(job, stageKey, title);

  if (part.state.status === "completed") {
    completeStage(job, stageKey, `${stageLabels[stageKey]} completed.`);

    if (stageKey === "svg_cleanup") {
      setStageActive(job, "openscad_build", `Starting ${stageLabels.openscad_build}.`);
    }
  }
}

async function handleEvent(job, client, event) {
  switch (event.type) {
    case "permission.asked": {
      await autoApprovePermission(client, job, event.properties);
      return;
    }

    case "question.asked": {
      await autoReplyToQuestion(client, job, event.properties);
      return;
    }

    case "command.executed": {
      job.commandStarted = true;
      job.status = "running";
      job.statusLine = `Running saved command \`${event.properties.name}\`.`;
      emitJob(job);

      const initialStage = job.pathway === "artwork" ? "magicimage" : "openscad_build";
      setStageActive(job, initialStage, `Starting ${stageLabels[initialStage]}.`);
      return;
    }

    case "todo.updated": {
      const activeTodo = event.properties.todos.find((todo) => todo.status === "in_progress");
      const nextTodo = activeTodo ?? event.properties.todos[0];

      if (nextTodo?.content) {
        job.statusLine = nextTodo.content;
        emitJob(job);
      }

      return;
    }

    case "session.idle": {
      if (event.properties.sessionID === job.sessionId) {
        await finalizeJob(job, client);
      }
      return;
    }

    case "session.status": {
      if (event.properties.status.type === "busy" && !terminalStatuses.has(job.status)) {
        job.status = "running";
        emitJob(job);
      }

      if (event.properties.status.type === "idle" && !terminalStatuses.has(job.status)) {
        job.statusLine = "OpenCode is finishing the current response.";
        emitJob(job);
      }

      return;
    }

    case "session.error": {
      if (isTransientFetchError(event.properties.error)) {
        job.statusLine = "Transient fetch issue reported by OpenCode. Continuing to monitor the run.";
        emitJob(job);
        return;
      }

      failJob(job, normalizeError(event.properties.error));
      return;
    }

    case "message.updated": {
      const error = event.properties.info.error;

      if (error) {
        if (isTransientFetchError(error)) {
          job.statusLine = "Transient fetch issue reported by OpenCode. Continuing to monitor the run.";
          emitJob(job);
          return;
        }

        failJob(job, normalizeError(error));
      }

      return;
    }

    case "message.part.updated": {
      const { part, delta } = event.properties;

      if (part.type === "subtask") {
        const stageKey = artworkSubagentStageByType[part.agent] ?? null;
        if (stageKey) {
          setStageActive(job, stageKey, part.description || `Running ${stageLabels[stageKey]}.`);
        }
        return;
      }

      if (part.type === "agent") {
        const stageKey = artworkSubagentStageByType[part.name] ?? null;
        if (stageKey) {
          setStageActive(job, stageKey, `Running ${stageLabels[stageKey]}.`);
        }
        return;
      }

      if (part.type === "tool") {
        trackSession(job, part.state.metadata?.sessionId);

        const stageKey = matchArtworkStageFromTaskTool(part) ?? matchLateStageFromBashTool(part);

        if (stageKey) {
          applyToolStage(job, stageKey, part);
        }

        const searchable = JSON.stringify({
          tool: part.tool,
          state: part.state,
          metadata: part.metadata,
        });

        const viewerUrl = extractCadViewerUrl(searchable);
        if (viewerUrl) {
          job.cadViewerUrl = viewerUrl;
          setStageActive(job, "cad_viewer", "Preparing CAD Viewer handoff.");
          completeStage(job, "cad_viewer", "CAD Viewer handoff ready.");
        }

        return;
      }

      if (part.type === "text") {
        const text = `${part.text}\n${delta ?? ""}`;
        const viewerUrl = extractCadViewerUrl(text);

        if (viewerUrl) {
          job.cadViewerUrl = viewerUrl;
          setStageActive(job, "cad_viewer", "Preparing CAD Viewer handoff.");
          completeStage(job, "cad_viewer", "CAD Viewer handoff ready.");
          return;
        }

        if (text.toLowerCase().includes("cad viewer")) {
          setStageActive(job, "cad_viewer", "Preparing CAD Viewer handoff.");
        }
      }

      return;
    }

    default:
      return;
  }
}

async function consumeJobEvents(job, client, eventStream, controller) {
  for await (const event of eventStream.stream) {
    if (controller.signal.aborted) {
      break;
    }

    if (!event || !jobTracksSession(job, eventSessionId(event))) {
      continue;
    }

    await handleEvent(job, client, event);

    if (terminalStatuses.has(job.status)) {
      break;
    }
  }
}

function waitFor(ms, signal) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      signal?.removeEventListener("abort", onAbort);
      resolve();
    }, ms);

    function onAbort() {
      clearTimeout(timer);
      reject(new Error("Aborted"));
    }

    if (signal?.aborted) {
      onAbort();
      return;
    }

    signal?.addEventListener("abort", onAbort, { once: true });
  });
}

async function startWatchingJobEvents(job, client) {
  const controller = new AbortController();
  job.eventAbortController = controller;

  void (async () => {
    while (!controller.signal.aborted && !terminalStatuses.has(job.status)) {
      try {
        const eventStream = await client.event.subscribe({ signal: controller.signal });
        await consumeJobEvents(job, client, eventStream, controller);
      } catch (error) {
        if (controller.signal.aborted || terminalStatuses.has(job.status)) {
          break;
        }

        job.statusLine = `Progress stream disconnected. Reconnecting after ${normalizeError(error)}.`;
        emitJob(job);
      }

      if (controller.signal.aborted || terminalStatuses.has(job.status)) {
        break;
      }

      try {
        await waitFor(1000, controller.signal);
      } catch {
        break;
      }
    }
  })();
}

async function runCommand(job, client, messageId) {
  try {
    await client.session.command({
      path: { id: job.sessionId },
      body: {
        command: job.commandName,
        arguments: "",
        messageID: messageId,
      },
    });

    job.commandStarted = true;
    if (!terminalStatuses.has(job.status)) {
      job.status = "running";
      emitJob(job);
    }
  } catch (error) {
    failJob(job, normalizeError(error));
  }
}

async function startJobRun(job) {
  const runtime = await getOpencodeRuntime();
  const { data: session } = await runtime.client.session.create({
    body: { title: `${job.pathway}: ${job.fileName}` },
  });

  job.sessionId = session.id;
  trackSession(job, session.id);
  job.statusLine = "Session created. Attaching the file.";
  emitJob(job);

  await startWatchingJobEvents(job, runtime.client);

  const attachment = await runtime.client.session.prompt({
    path: { id: session.id },
    body: {
      noReply: true,
      parts: [
        {
          type: "file",
          mime: "image/png",
          filename: job.fileName,
          url: pathToFileURL(job.storedFilePath).href,
        },
      ],
    },
  });

  job.statusLine = "File attached. Starting the saved workflow.";
  emitJob(job);
  void runCommand(job, runtime.client, attachment.data.info.id);
}

async function handleCreateJob(req, res, pathname) {
  if (isJobRunning()) {
    sendJson(res, 409, { error: "Only one active job is supported at a time." });
    return;
  }

  let formData;

  try {
    formData = await parseFormData(req, pathname);
  } catch {
    sendJson(res, 400, { error: "Expected multipart form data with one file." });
    return;
  }

  const pathway = formData.get("pathway");
  const files = formData.getAll("file");

  if (pathway !== "artwork" && pathway !== "technicaldrawing") {
    sendJson(res, 400, { error: "Choose either artwork or technicaldrawing." });
    return;
  }

  if (files.length !== 1) {
    sendJson(res, 400, { error: "Upload exactly one file." });
    return;
  }

  const uploadedFile = files[0];

  if (!(uploadedFile instanceof File)) {
    sendJson(res, 400, { error: "Missing file upload." });
    return;
  }

  if (uploadedFile.type !== "image/png" || !/\.png$/i.test(uploadedFile.name)) {
    sendJson(res, 400, { error: "Only PNG uploads are supported right now." });
    return;
  }

  const buffer = Buffer.from(await uploadedFile.arrayBuffer());

  if (!isPngBuffer(buffer)) {
    sendJson(res, 400, { error: "The uploaded file is not a valid PNG." });
    return;
  }

  const storedFilePath = path.join(uploadsDir, buildStoredFileName(uploadedFile.name));
  await fs.writeFile(storedFilePath, buffer);

  const job = createJob({
    fileName: uploadedFile.name,
    pathway,
    storedFilePath,
  });

  jobs.set(job.id, job);
  activeJobId = job.id;

  try {
    await startJobRun(job);
    sendJson(res, 200, snapshotJob(job));
  } catch (error) {
    if (job.eventAbortController && !job.eventAbortController.signal.aborted) {
      job.eventAbortController.abort();
    }
    jobs.delete(job.id);
    activeJobId = null;
    sendJson(res, 500, { error: normalizeError(error) });
  }
}

function attachSseClient(job, res) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache, no-transform",
    Connection: "keep-alive",
  });

  job.clients.add(res);
  res.write("retry: 1000\n\n");
  res.write(`data: ${JSON.stringify(snapshotJob(job))}\n\n`);

  const heartbeat = setInterval(() => {
    if (!res.destroyed) {
      res.write(": keepalive\n\n");
    }
  }, 15000);

  reqCleanup();

  function reqCleanup() {
    res.on("close", () => {
      clearInterval(heartbeat);
      job.clients.delete(res);
    });
  }
}

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
  });
  res.end(body);
}

async function serveStatic(res, fileInfo) {
  try {
    const contents = await fs.readFile(fileInfo.file);
    res.writeHead(200, { "Content-Type": fileInfo.type });
    res.end(contents);
  } catch {
    res.writeHead(404);
    res.end("Not found");
  }
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", `http://${req.headers.host ?? "127.0.0.1"}`);
  const pathname = url.pathname;

  try {
    if (req.method === "POST" && pathname === "/api/jobs") {
      await handleCreateJob(req, res, pathname);
      return;
    }

    const eventsMatch = pathname.match(/^\/api\/jobs\/([^/]+)\/events$/);
    if (req.method === "GET" && eventsMatch) {
      const job = jobs.get(eventsMatch[1]);

      if (!job) {
        sendJson(res, 404, { error: "Unknown job." });
        return;
      }

      attachSseClient(job, res);
      return;
    }

    const jobMatch = pathname.match(/^\/api\/jobs\/([^/]+)$/);
    if (req.method === "GET" && jobMatch) {
      const job = jobs.get(jobMatch[1]);

      if (!job) {
        sendJson(res, 404, { error: "Unknown job." });
        return;
      }

      sendJson(res, 200, snapshotJob(job));
      return;
    }

    if (req.method === "GET" && staticFiles[pathname]) {
      await serveStatic(res, staticFiles[pathname]);
      return;
    }

    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("Not found");
  } catch (error) {
    sendJson(res, 500, { error: normalizeError(error) });
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`OpenCode Workshop listening on http://127.0.0.1:${port}`);
});

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, async () => {
    try {
      if (opencodeRuntimePromise) {
        const runtime = await opencodeRuntimePromise;
        runtime.server?.close();
      }
    } finally {
      server.close(() => process.exit(0));
    }
  });
}
