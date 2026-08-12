/**
 * Port interface for spawning pi processes.
 *
 * Abstracts over tmux window spawning and direct subprocess execution.
 * The application layer depends on this port; adapters provide implementations.
 */

export interface SpawnOptions {
	readonly command: string;
	readonly args: readonly string[];
	readonly cwd: string;
	readonly windowName: string;
	readonly promptText: string;
	readonly signal?: AbortSignal;
}

export interface SpawnResult {
	readonly rawOutput: string;
	readonly stderr: string;
	readonly exitCode: number;
	readonly windowId: string | undefined;
	readonly durationMs: number;
}

export interface ProcessSpawner {
	readonly displayName: string;
	readonly isAvailable: boolean;
	spawn(options: SpawnOptions): Promise<SpawnResult>;
}
