## status for the Forth standard suite

| date | status | source |
|--|--|--|
| `Tue 31 Mar 2026` | passes file tests | [filetest.fth](forth-standard-test-suite/src/filetest.fth) |
| `Mon 30 Mar 2026` | passes exception tests | [exceptiontest.fth](forth-standard-test-suite/src/exceptiontest.fth) |
| `Sat 28 Mar 2026` | passes tools tests | [toolstest.fth](forth-standard-test-suite/src/toolstest.fth) |
| `Mon 27 Jan 2026` | passes struct tests | [facilitytest.fth](forth-standard-test-suite/src/facilitytest.fth) |
| `Mon 27 Jan 2026` | passes locals tests | [localstest.fth](forth-standard-test-suite/src/localstest.fth) |
| `Sat 24 Jan 2026` | passes search tests | [searchordertest.fth](forth-standard-test-suite/src/searchordertest.fth) |
| `Fri 23 Jan 2026` | passes string tests | [stringtest.fth](forth-standard-test-suite/src/stringtest.fth) |
| `Mon 19 Jan 2026` | passes double tests | [doubletest.fth](forth-standard-test-suite/src/doubletest.fth) |
| `Sun 18 Jan 2026` | passes core ext tests | [coreexttest.fth](forth-standard-test-suite/src/coreexttest.fth) |
| `Fri 16 Jan 2026` | passes core+ tests | [coreplustest.fth](forth-standard-test-suite/src/coreplustest.fth) |
| `Fri 16 Jan 2026` | passes core tests | [core.fth](forth-standard-test-suite/src/core.fr) |
| `Wed 14 Jan 2026` | passes preliminary tests | [prelimtest.fth](forth-standard-test-suite/src/prelimtest.fth) |

## not implemented

| type | status | source |
|--|--|--|
| blocks | possible, not planned without memory remaps | [blocktest.fth](forth-standard-test-suite/src/blocktest.fth) |
| system memory | no system allocator available | [memorytest.fth](forth-standard-test-suite/src/memorytest.fth) |
| floating point | possible w/ emulation, not started | [fp](forth-standard-test-suite/src/fp/) |
