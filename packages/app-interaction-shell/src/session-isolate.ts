export class SessionIsolate {
  private readonly tails = new Map<string, Promise<unknown>>();

  enqueue<T>(documentId: string, task: () => Promise<T> | T): Promise<T> {
    const previous = this.tails.get(documentId) ?? Promise.resolve();
    const next = previous.catch(() => undefined).then(() => task());
    this.tails.set(
      documentId,
      next.then(
        () => undefined,
        () => undefined,
      ),
    );
    return next;
  }
}
