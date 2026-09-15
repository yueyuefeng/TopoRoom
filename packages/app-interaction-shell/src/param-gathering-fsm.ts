export interface ToolStep<TName extends string = string, TValue = unknown> {
  name: TName;
  parse: (value: unknown) => TValue;
}

export interface ToolDefinition<TDraft = unknown> {
  readonly id: string;
  readonly steps: readonly ToolStep[];
  complete(params: Record<string, unknown>): TDraft;
}

export type FsmState = `awaiting_${string}` | "complete";

export class ParamGatheringFSM<TDraft> {
  private readonly collected = new Map<string, unknown>();
  private index = 0;

  private constructor(private readonly tool: ToolDefinition<TDraft>) {}

  static forTool<TDraft>(tool: ToolDefinition<TDraft>): ParamGatheringFSM<TDraft> {
    return new ParamGatheringFSM(tool);
  }

  get state(): FsmState {
    if (this.index >= this.tool.steps.length) {
      return "complete";
    }
    const step = this.tool.steps[this.index];
    if (!step) {
      return "complete";
    }
    return `awaiting_${step.name}`;
  }

  provide(stepName: string, raw: unknown): TDraft | undefined {
    const step = this.tool.steps[this.index];
    if (!step) {
      throw new Error(`${this.tool.id} is already complete`);
    }
    if (step.name !== stepName) {
      throw new Error(
        `${this.tool.id} is awaiting '${step.name}', not '${stepName}'`,
      );
    }
    this.collected.set(step.name, step.parse(raw));
    this.index += 1;
    if (this.index >= this.tool.steps.length) {
      return this.tool.complete(Object.fromEntries(this.collected));
    }
    return undefined;
  }
}
