import type { ToolDefinition } from "./param-gathering-fsm.js";

export class ToolRegistry {
  private readonly tools = new Map<string, ToolDefinition>();

  register(tool: ToolDefinition): void {
    if (this.tools.has(tool.id)) {
      throw new Error(`Tool '${tool.id}' is already registered`);
    }
    this.tools.set(tool.id, tool);
  }

  get(id: string): ToolDefinition {
    const tool = this.tools.get(id);
    if (!tool) {
      throw new Error(`Unknown tool '${id}'`);
    }
    return tool;
  }

  list(): readonly ToolDefinition[] {
    return [...this.tools.values()];
  }
}
