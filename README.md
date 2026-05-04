# Hex Maze

Central workspace for testing and debugging the Voigts Lab hex-maze firmware,
Python interface, Arduino libraries, and PCB references.

The maze has seven clusters. Each cluster has seven prisms, for a total of
forty-nine prisms. The host Python interface talks to clusters over Ethernet on
TCP port `7777`, with cluster addresses normally mapped to
`192.168.10.10` through `192.168.10.16`.

## Submodules

| Path | Purpose |
| --- | --- |
| `firmware/ClusterController` | Cluster firmware |
| `software/hex_maze_interface_python` | Python API, CLI, and hardware tests |
| `libraries/TMC51X0` | TMC5130/TMC5160 driver/controller library |
| `libraries/TCA6408` | TCA6408 address expander library |
| `pcb/cluster-pcb` | Cluster PCB KiCad project |
| `pcb/prism-pcb` | Prism PCB KiCad project |

Clone with submodules:

```sh
git clone --recursive git@github.com:symbiosystem/hex-maze.git
```

Or initialize submodules after cloning:

```sh
git submodule update --init --recursive
```

## Common Commands

```sh
make submodule-status
make firmware-build
make python-test
make desk-verify
make desk-smoke
make desk-repeated-home
```

Hardware movement commands assume the attached rig is powered, clear to move,
and reachable on the `192.168.10.0/24` network.

## Current Debug Focus

The main intermittent issue is a prism that does not move after homing even
though other prisms move normally. Existing notes in `firmware/ClusterController`
identify a related repeated-home state inconsistency:

- `homed = false`
- `home_outcome = STALL`
- `position = 0`

The central workflow is to reproduce the issue with Python hardware tests,
instrument firmware only when needed, commit fixes in the owning submodule, and
then update this repository's submodule pointer to preserve the tested state.
