## status for the 2012 suite

| date | status | source |
|--|--|--|
| `Tue 31 Mar 2026` | passes file tests | [filetest.fth](forth2012-test-suite/src/filetest.fth) |
| `Mon 30 Mar 2026` | passes exception tests | [exceptiontest.fth](forth2012-test-suite/src/exceptiontest.fth) |
| `Sat 28 Mar 2026` | passes tools tests | [toolstest.fth](forth2012-test-suite/src/toolstest.fth) |
| `Mon 27 Jan 2026` | passes struct tests | [facilitytest.fth](forth2012-test-suite/src/facilitytest.fth) |
| `Mon 27 Jan 2026` | passes locals tests | [localstest.fth](forth2012-test-suite/src/localstest.fth) |
| `Sat 24 Jan 2026` | passes search tests | [searchordertest.fth](forth2012-test-suite/src/searchordertest.fth) |
| `Fri 23 Jan 2026` | passes string tests | [stringtest.fth](forth2012-test-suite/src/stringtest.fth) |
| `Mon 19 Jan 2026` | passes double tests | [doubletest.fth](forth2012-test-suite/src/doubletest.fth) |
| `Sun 18 Jan 2026` | passes core ext tests | [coreexttest.fth](forth2012-test-suite/src/coreexttest.fth) |
| `Fri 16 Jan 2026` | passes core+ tests | [coreplustest.fth](forth2012-test-suite/src/coreplustest.fth) |
| `Fri 16 Jan 2026` | passes core tests | [core.fth](forth2012-test-suite/src/core.fr) |
| `Wed 14 Jan 2026` | passes preliminary tests | [prelimtest.fth](forth2012-test-suite/src/prelimtest.fth) |

## not implemented

| type | status | source |
|--|--|--|
| blocks | possible, not planned without memory remaps | [blocktest.fth](forth2012-test-suite/src/blocktest.fth) |
| system memory | no system allocator available | [memorytest.fth](forth2012-test-suite/src/memorytest.fth) |
| floating point | possible w/ emulation, not started | [fp](forth2012-test-suite/src/fp/) |
