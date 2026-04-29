const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

let panel = undefined;
let client = undefined;
let history = [];

const TOOLS = [
  {
    name: 'read_file',
    description: 'Read the contents of a file in the workspace.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Absolute or workspace-relative file path' },
      },
      required: ['path'],
    },
  },
  {
    name: 'list_directory',
    description: 'List files and subdirectories at a given path.',
    input_schema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'Directory path to list' },
      },
      required: ['path'],
    },
  },
];

function getClient() {
  if (client) return client;
  const Anthropic = require('@anthropic-ai/sdk');
  const config = vscode.workspace.getConfiguration('claudeAgent');
  const apiKey = config.get('apiKey') || process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error('No API key found. Set claudeAgent.apiKey in settings or ANTHROPIC_API_KEY env var.');
  }
  client = new Anthropic({ apiKey });
  return client;
}

function getWorkspacePath() {
  return vscode.workspace.workspaceFolders?.[0]?.uri?.fsPath || '';
}

function resolveFilePath(filePath) {
  if (path.isAbsolute(filePath)) return filePath;
  const ws = getWorkspacePath();
  return ws ? path.join(ws, filePath) : filePath;
}

function executeTool(name, input) {
  try {
    if (name === 'read_file') {
      const resolved = resolveFilePath(input.path);
      const content = fs.readFileSync(resolved, 'utf8');
      return content.length > 20000 ? content.slice(0, 20000) + '\n...(truncated)' : content;
    }
    if (name === 'list_directory') {
      const resolved = resolveFilePath(input.path);
      const entries = fs.readdirSync(resolved, { withFileTypes: true });
      return entries
        .map(e => (e.isDirectory() ? `[DIR]  ${e.name}` : `       ${e.name}`))
        .join('\n');
    }
  } catch (err) {
    return `Error: ${err.message}`;
  }
  return `Unknown tool: ${name}`;
}

function buildSystem() {
  const ws = getWorkspacePath();
  const activeFile = vscode.window.activeTextEditor?.document?.uri?.fsPath || '';
  let sys = 'You are a helpful AI coding assistant with access to the user\'s VS Code workspace.\n';
  if (ws) sys += `\nWorkspace root: ${ws}`;
  if (activeFile) sys += `\nCurrently open file: ${activeFile}`;
  sys += '\n\nYou can use read_file and list_directory to explore the codebase. Be concise. Use markdown code blocks with language tags.';
  return sys;
}

async function handleUserMessage(text) {
  history.push({ role: 'user', content: text });

  const ai = getClient();
  let continueLoop = true;

  while (continueLoop) {
    panel.webview.postMessage({ type: 'thinking' });

    const response = await ai.messages.create({
      model: 'claude-opus-4-7',
      max_tokens: 8192,
      thinking: { type: 'adaptive' },
      system: buildSystem(),
      tools: TOOLS,
      messages: history,
    });

    history.push({ role: 'assistant', content: response.content });

    // Stream text blocks to the webview
    const textParts = response.content.filter(b => b.type === 'text').map(b => b.text);
    if (textParts.length > 0) {
      panel.webview.postMessage({ type: 'assistant', text: textParts.join('') });
    }

    if (response.stop_reason === 'tool_use') {
      const toolResults = [];
      for (const block of response.content) {
        if (block.type !== 'tool_use') continue;
        panel.webview.postMessage({
          type: 'tool_call',
          name: block.name,
          input: block.input,
        });
        const result = executeTool(block.name, block.input);
        toolResults.push({
          type: 'tool_result',
          tool_use_id: block.id,
          content: result,
        });
      }
      history.push({ role: 'user', content: toolResults });
    } else {
      continueLoop = false;
    }
  }

  panel.webview.postMessage({ type: 'done' });
}

function activate(context) {
  const openCmd = vscode.commands.registerCommand('claudeAgent.open', () => {
    if (panel) {
      panel.reveal(vscode.ViewColumn.Beside);
      return;
    }

    panel = vscode.window.createWebviewPanel(
      'claudeAgent',
      'Claude Agent',
      vscode.ViewColumn.Beside,
      {
        enableScripts: true,
        retainContextWhenHidden: true,
        localResourceRoots: [vscode.Uri.joinPath(context.extensionUri, 'media')],
      }
    );

    const htmlPath = path.join(context.extensionPath, 'media', 'chat.html');
    panel.webview.html = fs.readFileSync(htmlPath, 'utf8');

    panel.webview.onDidReceiveMessage(async msg => {
      if (msg.type === 'send') {
        try {
          await handleUserMessage(msg.text);
        } catch (err) {
          panel.webview.postMessage({ type: 'error', text: err.message });
        }
      } else if (msg.type === 'clear') {
        history = [];
        panel.webview.postMessage({ type: 'cleared' });
      }
    });

    panel.onDidDispose(() => {
      panel = undefined;
    });
  });

  const clearCmd = vscode.commands.registerCommand('claudeAgent.clear', () => {
    history = [];
    panel?.webview.postMessage({ type: 'cleared' });
  });

  context.subscriptions.push(openCmd, clearCmd);
}

function deactivate() {}

module.exports = { activate, deactivate };
