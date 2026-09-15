import { describe, expect, it } from "vitest";
import { SessionIsolate } from "./session-isolate.js";

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

describe("SessionIsolate", () => {
  it("serializes concurrent writes for the same documentId", async () => {
    const isolate = new SessionIsolate();
    const log: number[] = [];

    const first = isolate.enqueue("doc_1", async () => {
      await delay(40);
      log.push(1);
      return "a";
    });
    const second = isolate.enqueue("doc_1", async () => {
      log.push(2);
      return "b";
    });

    await expect(Promise.all([first, second])).resolves.toEqual(["a", "b"]);
    expect(log).toEqual([1, 2]);
  });

  it("does not let a later write on the same document overtake an in-flight write", async () => {
    const isolate = new SessionIsolate();
    let shared = 0;

    const slow = isolate.enqueue("doc_1", async () => {
      const snapshot = shared;
      await delay(30);
      shared = snapshot + 1;
    });
    const fast = isolate.enqueue("doc_1", async () => {
      shared += 1;
    });

    await Promise.all([slow, fast]);
    expect(shared).toBe(2);
  });

  it("allows different documentIds to proceed concurrently", async () => {
    const isolate = new SessionIsolate();
    let otherStartedWhileFirstBlocked = false;

    const first = isolate.enqueue("doc_a", async () => {
      await delay(40);
    });
    const second = isolate.enqueue("doc_b", async () => {
      otherStartedWhileFirstBlocked = true;
    });

    await Promise.all([first, second]);
    expect(otherStartedWhileFirstBlocked).toBe(true);
  });

  it("propagates task errors without stalling the queue", async () => {
    const isolate = new SessionIsolate();
    const failed = isolate.enqueue("doc_1", async () => {
      throw new Error("boom");
    });
    const recovered = isolate.enqueue("doc_1", async () => "ok");

    await expect(failed).rejects.toThrow("boom");
    await expect(recovered).resolves.toBe("ok");
  });
});
