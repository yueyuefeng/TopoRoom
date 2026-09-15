export class Room {
  constructor(
    readonly id: string,
    readonly wallIds: readonly string[],
  ) {}
}
