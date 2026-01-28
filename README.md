## w4

What you found is a [Forth](https://forth-standard.org/) interpreter (and possibly a compiler in the future) implemented with [WAT](https://developer.mozilla.org/en-US/docs/WebAssembly/Guides/Understanding_the_text_format) using [WASI](https://github.com/WebAssembly/WASI/blob/main/docs/Proposals.md) to ensure compatibility accross platforms.


## requirements

There are a couple of tools needed to actually build and run the demos. There certainly should not be the need for installation-fatigue, so it is meant to be kept simple:

- [make](https://en.wikipedia.org/wiki/Make_(software)) - A very widely used toolset, if you've compiled anything before, it _should_ be available on your machine. Used to run the build & test scripts and keep it lean.
- [m4](https://en.wikipedia.org/wiki/M4_(computer_language)) - Used for macro processing, specifically around includes for sources. It should be included if you are using a unix-y OS.
- [sed](https://en.wikipedia.org/wiki/Sed) - Provides some cleanups for sources when combined. As with m4, it should be availble on a unix-y OS.
- [find](https://en.wikipedia.org/wiki/Find_(Unix)) - Used in the Makefile to build a source list, standard on unix-y OS.
- [wat2wasm & wasmopt](https://github.com/WebAssembly/wabt) - Used to build the WAT sources.
- (optional) [node](https://nodejs.org/en) - Used to run the included `w4.js` sample (other language bridges should follow).


## building

`make clean && make` will build the source (assuming a unix-y OS) into the `build/` folder.


## executing

Currently only a Node wrapper is available to execute a single file. After building, you can do `node w4.js example.f` which will execute the code in `example.f`.

Something useful in development has been `make clean && make && ls -al build && node w4.js example.f` (everything is still small enough that there is no major penalty to do _everything_ in the build)


## testing

The core tests are from the [forth2012-test-suite](https://github.com/gerryjackson/forth2012-test-suite). Instead of just copying, these are added as a git submodule. On a fresh clone, this is not immediate available, so a couple of command are needed to pull it down (if you wish to run the tests).

- `git submodule init` initializes the submodules
- `git submodule update` updates the actual code from the test suite

At the root, tests can be executed with `make check` to execute both the built-in tests (for functionality not fully tested in the standard suite) as well as the tests pulled it by the git submodule, ensuring compliance to a wide range of Forth tests.


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

**The build is weird** WAT doesn't quite have includes. There needed to be a minimal overhead way to just combine stuff so there is no single 100k file to edit. `m4` is available, it is being used.

**It is not quite ready to be packaged** Yes, sadly. The `w4.js` for instance looking for `build/w4-opt.wasm` and it assumes a root `w4/w4.f` for the Forth sources. These 3 folders can be copied as-is? Non-optimal, it is what it is (at this point).

**I don't like the name** Cannot say the author is over-the-moon with it either. Something about naming and coding... Either way, renames can be on the cards, the builtin lib will (most probably) stay at `w4/w4.f`, but the repo and actual runnable executables can be whatever.
