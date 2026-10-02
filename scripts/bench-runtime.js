'use strict';

import fs from 'node:fs';
import { createHash } from 'node:crypto';
import os from 'node:os';
import path from 'node:path';
import process from 'node:process';
import { WASI } from 'node:wasi';

/** @typedef {{ memory: WebAssembly.Memory, alloc: (len: number) => number, evaluate: (ptr: number, len: number) => void } & WebAssembly.Exports} WasmExports */

/** @returns {number} */
function count (/** @type {string} */ name, /** @type {number} */ fallback) {
	const value = Number(process.env[name] ?? fallback);

	if (!Number.isSafeInteger(value) || value < 1) {
		throw new Error(`${name} must be a positive integer`);
	}

	return value;
}

const runs = count('RUNS', 7);
const warmup = count('WARMUP', 3);
const root = path.resolve(import.meta.dirname, '..');
const wasmPath = path.resolve(process.env['W4_WASM'] ?? path.join(root, 'build/w4-opt.wasm'));
const wasmBytes = fs.readFileSync(wasmPath);
const now = () => process.hrtime.bigint();
const elapsed = (/** @type {bigint} */ start) => Number(now() - start) / 1e6;
const wasi = new WASI({
	version: 'preview1',
	args: [],
	env: {},
	preopens: { '/usr': path.join(root, 'test/bench') }
});

let start = now();
const module = await WebAssembly.compile(wasmBytes);
const compileMs = elapsed(start);
start = now();
const instance = await WebAssembly.instantiate(module, wasi.getImportObject());
const instantiateMs = elapsed(start);
const exposed = /** @type {WasmExports} */ (instance.exports);
start = now();
wasi.start(instance);
const bootstrapMs = elapsed(start);

// Allocate source and command buffers before measuring execution.
function prepare (/** @type {Uint8Array} */ bytes) {
	const ptr = exposed.alloc(bytes.length + 1);

	new Uint8Array(exposed.memory.buffer, ptr, bytes.length).set(bytes);

	return () => exposed.evaluate(ptr, bytes.length);
}

const define = prepare(Buffer.from('s" runtime.f" included'));
start = now();
define();
const definitionsMs = elapsed(start);
const cases = [
	{ name: 'sum', expected: 49995000 },
	{ name: 'calls', expected: 10000 },
	{ name: 'branches', expected: 15000 },
	{ name: 'memory', expected: 10000 }
].map(({ name, expected }) => ({
	name,
	expected,
	run: prepare(Buffer.from(`bench-${name}`)),
	/** @type {number[]} */
	samplesMs: []
}));
const view = new DataView(exposed.memory.buffer);
// Memory layout and count-prefixed stacks are defined in wat/memory.wat
// and wat/stack.wat. Keep these checks in sync if that layout changes.
const stack = view.getUint32(0x0140, true);
const returnStack = view.getUint32(0x0144, true);
const returnDepth = view.getUint32(returnStack, true);

if (view.getUint32(stack, true) !== 0) {
	throw new Error('Benchmark setup left values on the data stack');
}

// Verify the result and stack balance outside the measured interval.
function sample (/** @type {typeof cases[number]} */ entry) {
	const before = now();

	entry.run();

	const ms = elapsed(before);
	const depth = view.getUint32(stack, true);
	const result = view.getInt32(stack + 4, true);

	if (depth !== 1 || result !== entry.expected) {
		throw new Error(`${entry.name}: expected one result ${entry.expected}, got depth=${depth}, result=${result}`);
	}

	if (view.getUint32(returnStack, true) !== returnDepth) {
		throw new Error(`${entry.name}: return stack is unbalanced`);
	}

	view.setUint32(stack, 0, true);

	return ms;
}

for (let i = 0; i < warmup; i++) {
	for (const entry of cases) sample(entry);
}

// Interleave workloads so every case sees the same stage of the process.
for (let i = 0; i < runs; i++) {
	for (const entry of cases) entry.samplesMs.push(sample(entry));
}

console.log(JSON.stringify({
	node: process.version,
	platform: process.platform,
	arch: process.arch,
	cpu: os.cpus()[0]?.model,
	wasmPath,
	wasmBytes: wasmBytes.length,
	wasmSha256: createHash('sha256').update(wasmBytes).digest('hex'),
	runs,
	warmup,
	setupMs: { compile: compileMs, instantiate: instantiateMs, bootstrap: bootstrapMs, definitions: definitionsMs },
	workloads: cases.map(({ name, samplesMs }) => {
		const sorted = [...samplesMs].sort((a, b) => a - b);
		const middle = Math.floor(sorted.length / 2);
		const upper = /** @type {number} */ (sorted[middle]);
		const lower = /** @type {number} */ (sorted[Math.floor((sorted.length - 1) / 2)]);

		return {
			name,
			samplesMs,
			minMs: sorted[0],
			medianMs: (lower + upper) / 2,
			maxMs: sorted[sorted.length - 1]
		};
	})
}, null, 2));
