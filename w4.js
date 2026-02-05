'use strict';

/** @typedef {{ memory: WebAssembly.Memory, alloc: (len: number) => number, evaluate: (ptr: number, len: number) => void } & WebAssembly.Exports} WasmExports */

import nodeFs from 'node:fs';
import nodePath from 'node:path';
import nodeProcess from 'node:process';
import nodeWasi from 'node:wasi';

(async () => {
	// exposed forward
	let /** @type {WasmExports | null} */ exposed = null
	let /** @type {DataView | null} */ memview = null;

	/** @returns {void} */
	function evaluate (/** @type {string} */ code) {
		if (!exposed || !memview) {
			throw new Error('Invalid exposed object');
		}

		const len = code.length;
		const ptr = exposed.alloc(len + 1);

		for (let i = 0; i < len; i++) {
			memview.setUint8(ptr + i, code.charCodeAt(i));
		}

		exposed.evaluate(ptr, len);
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

	// start the timers for ok/err
	console.time('ok');
	console.time('err');

	// arguments
	const argv = nodeProcess.argv.slice(2);
	const cmdFile = nodePath.basename(import.meta.filename);

	// ensure we have a source file
	if (!argv.length || !argv[0]) {
		console.log(`Usage: ${cmdFile} <file.f>`);
		nodeProcess.exit(-1);
	}

	// get path & file
	const usrFull = nodePath.join(nodeProcess.cwd(), argv[0]);
	const usrPath = nodePath.dirname(usrFull);
	const usrFile = nodePath.basename(usrFull);
	const libPath = nodePath.join(import.meta.dirname, 'build');

	try {
		// instantiate WASM, including getting a memory view
		const wasi = new nodeWasi.WASI({
			args: nodeProcess.argv,
  			env: nodeProcess.env,
			preopens: {
				/* fd:3 */ '/usr': usrPath
			},
			stdin: nodeProcess.stdin.fd,
  			stdout: nodeProcess.stdout.fd,
  			stderr: nodeProcess.stderr.fd,
			version: 'preview1'
		});
		const wasm = await WebAssembly.compile(nodeFs.readFileSync(nodePath.join(libPath, 'w4-opt.wasm')));
		const instance = await WebAssembly.instantiate(wasm, { ...wasi.getImportObject() });

		// store exposed interface
		exposed = /** @type {WasmExports} */ (instance.exports);
		memview = new DataView(exposed.memory.buffer);

		// initialize the engine (underlying it calls the _start export)
		wasi.start(instance);

		evaluate(`s" ${usrFile}" included`);

		logEnd('ok');
	} catch (e) {
		logEnd('err');

		console.error(/** @type {Error} */ (e).message);
		console.error(e);
		nodeProcess.exit(1);
	}
})();
