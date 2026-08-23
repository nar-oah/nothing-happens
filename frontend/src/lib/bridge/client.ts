import type {
	InboundMessage,
	OutboundMessage,
	OutboundPayloads,
	OutboundType,
	RequestId
} from './protocol.ts';
import { CommandError } from './protocol.ts';
import { decodeInboundMessage, encodeOutboundMessage } from './validation.ts';

export type CefBridgeWindow = Window & {
	sendIpcMessage: (message: string) => void;
	ipcMessage: {
		addListener(listener: CefIpcListener): void;
		removeListener?(listener: CefIpcListener): void;
	};
};

export type CefIpcClientOptions = {
	onMessage: (message: InboundMessage) => void;
	onProtocolError?: (error: string, raw: string) => void;
	requestPrefix?: string;
};

type PendingRequest = {
	resolve: (message: InboundMessage) => void;
	reject: (error: Error) => void;
};

export function hasCefBridge(
	target: Window | undefined = currentWindow()
): target is CefBridgeWindow {
	return (
		target !== undefined &&
		typeof target.sendIpcMessage === 'function' &&
		typeof target.ipcMessage?.addListener === 'function'
	);
}

export const isCefBridgeAvailable = hasCefBridge;

export function createCefIpcClient(options: CefIpcClientOptions): CefIpcClient | null {
	const target = currentWindow();
	return hasCefBridge(target) ? new CefIpcClient(target, options) : null;
}

export class CefIpcClient {
	readonly target: CefBridgeWindow;
	readonly onMessage: CefIpcClientOptions['onMessage'];
	readonly onProtocolError?: CefIpcClientOptions['onProtocolError'];

	private readonly requestPrefix: string;
	private readonly pending = new Map<RequestId, PendingRequest>();
	private readonly receiveListener: CefIpcListener;
	private requestSequence = 0;
	private connected = false;

	constructor(target: CefBridgeWindow, options: CefIpcClientOptions) {
		this.target = target;
		this.onMessage = options.onMessage;
		this.onProtocolError = options.onProtocolError;
		this.requestPrefix = options.requestPrefix ?? 'ui';
		this.receiveListener = (raw) => this.receive(raw);
	}

	connect(): void {
		if (this.connected) return;
		this.target.ipcMessage.addListener(this.receiveListener);
		this.connected = true;
		this.send('ui.ready', {});
	}

	send<T extends OutboundType>(type: T, payload: OutboundPayloads[T], requestId?: RequestId): void {
		const message = { type, payload, ...(requestId ? { request_id: requestId } : {}) };
		this.target.sendIpcMessage(encodeOutboundMessage(message as OutboundMessage));
	}

	request<T extends OutboundType>(type: T, payload: OutboundPayloads[T]): Promise<InboundMessage> {
		const requestId = `${this.requestPrefix}-${++this.requestSequence}`;
		return new Promise((resolve, reject) => {
			this.pending.set(requestId, { resolve, reject });
			this.send(type, payload, requestId);
		});
	}

	destroy(): void {
		if (this.connected) this.target.ipcMessage.removeListener?.(this.receiveListener);
		this.connected = false;
		for (const pending of this.pending.values()) pending.reject(new Error('IPC client destroyed'));
		this.pending.clear();
	}

	private receive(raw: string): void {
		const decoded = decodeInboundMessage(raw);
		if (!decoded.ok) {
			this.onProtocolError?.(decoded.error, raw);
			return;
		}

		const message = decoded.value;
		this.onMessage(message);
		if (!message.request_id) return;
		const pending = this.pending.get(message.request_id);
		if (!pending) return;
		this.pending.delete(message.request_id);
		if (message.type === 'command.error') {
			pending.reject(new CommandError(message.payload, message.request_id));
			return;
		}
		pending.resolve(message);
	}
}

function currentWindow(): Window | undefined {
	return typeof window === 'undefined' ? undefined : window;
}
