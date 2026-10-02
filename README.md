## w4

What you found is a [Forth](https://forth-standard.org/) interpreter implemented with [WAT](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Understanding_the_text_format) using [WASI](https://github.com/WebAssembly/WASI/blob/main/docs/Proposals.md) to ensure compatibility accross runtimes.


## requirements

There are a couple of tools needed to actually build and run the demos. There certainly should not be the need for installation-fatigue, so it is meant to be kept simple:

- [wat2wasm & wasmopt](https://github.com/WebAssembly/wabt) - Used to build the WAT sources.
- (optional) [node](https://nodejs.org/en) - Used to run the included `w4.js` sample (other language bridges should follow).

Additionally some standard Unix-y tools (these should be already available in your environment) are required for the build process, these are:

[awk](https://en.wikipedia.org/wiki/AWK), [cat](https://en.wikipedia.org/wiki/Cat_(Unix)), [find](https://en.wikipedia.org/wiki/Find_(Unix)), [m4](https://en.wikipedia.org/wiki/M4_(computer_language)), [make](https://en.wikipedia.org/wiki/Make_(software)), [tee](https://en.wikipedia.org/wiki/Tee_(command)) and [wc](https://en.wikipedia.org/wiki/Wc_(Unix))


## building

`make clean && make` will build the source (assuming a unix-y OS) into the `build/` folder.


## executing

Currently only a Node wrapper is available to execute a single file. After building, you can do `node w4.js <file.f>` which will execute the code in your `<file.f>`.

Something useful in development has been `make clean && make check && ls -al build` (everything is still small enough that there is no major penalty to do _everything_ in the build)


## testing

The core tests are from the [forth-standard-test-suite](https://github.com/Forth-Standard/forth-standard-test-suite), maintained by Forth-Standard following the transfer from Gerry Jackson. The suite is pinned as a git submodule at `test/forth-standard-test-suite`.

On a fresh clone, download the pinned suite with `git submodule update --init --recursive`.
For an existing checkout after the migration, synchronize the URL and initialize the renamed submodule:

```sh
git submodule sync --recursive
git submodule update --init --recursive
```

At the root, tests can be executed with `make check` to execute both the built-in tests (for functionality not fully tested in the standard suite) as well as the tests pulled it by the git submodule, ensuring compliance to a wide range of Forth tests.


## execution benchmarks

`make bench-runtime` measures arithmetic loops, word calls, branches, and memory
access in one initialized interpreter. Each workload runs 10,000 iterations;
definitions and command buffers are prepared before timing. Results and stack
balance are checked after every sample, outside the measured interval.

Use `make bench-runtime RUNS=9 WARMUP=5` to change the sample counts (both must be
positive integers). JSON output includes individual samples, medians, runtime and
CPU details, the Wasm SHA-256, and separate Wasm compilation, instantiation, Forth
bootstrap, and workload loading/compilation timings. Samples include evaluating the
workload name, but exclude setup, validation, and output. These synthetic workloads
complement the test suite; they do not represent every Forth program.

For a JSON file, run:

```sh
node --disable-warning=ExperimentalWarning scripts/bench-runtime.js > build/runtime-baseline.json
```

Set `W4_WASM` to compare a saved Wasm binary. Run comparisons on an otherwise idle
machine and repeat them before concluding a change is faster. `make bench-std`
remains available for whole-suite timings, including startup and compilation.


## future

For now it is being put out there since the overhead of not having pull requests and tracking is certainly not great for playing with this. Since (as at the writing of this) it is unfinished-but-working, it is/was in a good place to push it somewhere. That somewhere is what you see here.

Current plans are -

- make it forth-2012 compilant (extend and build missing words for identified modules)
- cater for an interactive evaluation environment (bonus: available on the web) - it focussses on interpreting files and then exiting
- expand this into a forth2wat compiler
- ... probably a lot of other things


## faq

**Why forth?** I dunno, but have been facinated with it since the late 1980's when I went through my asm86 phase. It certainly is a "simple" interpreter.

**Why wasm?** I assume you meant wat? Like forth, it is a lower-level assembly-like language. Like forth, it is an interest and something I wanted to explore and get better at. (Like with Forth, proficiency is a WIP.)

**The directory structure is weird** Certainly. All `wat` (combined into 1 via `m4`) inside `wat/` and the forth libs in `w4/`. No specific `src/` at this point.

**The build is weird** WAT doesn't quite have includes. There needed to be a minimal overhead way to just combine stuff so there is no single 100k file to edit. `m4` is available, it is being used. Forth does have includes, but we bundle it into the WAT, once again combining the sources via `m4`.

**I don't like the name** Cannot say the author is over-the-moon with it either. Something about naming and coding... Either way, renames can be on the cards, the builtin lib will (most probably) stay at `w4/w4.f`, but the repo and actual runnable executables can be whatever.
