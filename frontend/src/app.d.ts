// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	type CefIpcListener = (message: string) => void;

	interface Window {
		sendIpcMessage?: (message: string) => void;
		ipcMessage?: {
			addListener(listener: CefIpcListener): void;
			removeListener?(listener: CefIpcListener): void;
		};
	}

	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};
