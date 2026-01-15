'use strict';

/** @typedef {{ memory: WebAssembly.Memory, alloc: (len: number) => number, evaluate: (code: number, len: number) => void, evaluate_file: (str: number, len: number) => void } & WebAssembly.Exports} WasmExports */

import nodeFs from 'node:fs';
import nodePath from 'node:path';
import nodeProcess from 'node:process';
import nodeWasi from 'node:wasi';

(async () => {
	// arguments
	const cmd = nodePath.basename(nodeProcess.argv[1] || 'w4.js');
	const argv = nodeProcess.argv.slice(2);

	// exposed forward
	let /** @type {WasmExports | null} */ exposed = null
	let /** @type {DataView | null} */ memview = null;

	/** @returns {void} */
	function evaluateFile (/** @type {string} */ file) {
		if (!exposed || !memview) {
			throw new Error('Invalid exposed object');
		}

		const len = file.length;
		const ptr = exposed.alloc(len + 1);

		for (let i = 0; i < len; i++) {
			memview.setUint8(ptr + i, file.charCodeAt(i));
		}

		exposed.evaluate_file(ptr, len);
	}

	/** @returns {void} */
	function logEnd (/** @type {string} */ label) {
		console.log();
		console.timeEnd(label);

		if (memview) {
			const now = Math.ceil(memview.getUint32(0x0100, true) / 1024);
			const max = Math.ceil(memview.getUint32(0x0108, true) / 1024);

			console.log(`${now.toLocaleString()}kB used (${max.toLocaleString()}kB max)`);
		}
	}

	// ensure we have a source file
	if (!argv.length || !argv[0]) {
		console.log(`Usage: ${cmd} <file.f>`);
		nodeProcess.exit(-1);
	}

	// start the timers for ok/err
	console.time('ok');
	console.time('err');

	try {
		// instantiate WASM, including getting a memory view
		const wasi = new nodeWasi.WASI({
			args: nodeProcess.argv,
  			env: nodeProcess.env,
			preopens: {
				// user location first, default for includes/requires
				/* fd:3 */ '/app': nodeProcess.cwd(),
				/* fd:4 */ '/lib': import.meta.dirname,
			},
			stdin: nodeProcess.stdin.fd,
  			stdout: nodeProcess.stdout.fd,
  			stderr: nodeProcess.stderr.fd,
			version: 'preview1'
		});
		const wasm = await WebAssembly.compile(nodeFs.readFileSync('build/w4-opt.wasm'));
		const instance = await WebAssembly.instantiate(wasm, { ...wasi.getImportObject() });

		// store exposed interface
		exposed = /** @type {WasmExports} */ (instance.exports);
		memview = new DataView(exposed.memory.buffer);

		// initialize the engine (underlying it calls the _start export)
		wasi.start(instance);

		evaluateFile(argv[0]);

		logEnd('ok');
	} catch (e) {
		logEnd('err');

		console.error(/** @type {Error} */ (e).message);
		console.error(e);
		nodeProcess.exit(1);
	}
})();
