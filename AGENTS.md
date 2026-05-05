# Hex Maze Agent Notes

This repository is the central workspace for testing and debugging the hex-maze
hardware. The firmware, Python interface, Arduino libraries, and PCB projects
live in git submodules and keep their own commit histories.

## Repository Layout

- `firmware/ClusterController`: RP2040/W5500 cluster firmware.
- `software/hex_maze_interface_python`: Python API, CLI, and hardware tests.
- `libraries/TMC51X0`: TMC5130/TMC5160 motion-control library.
- `libraries/TCA6408`: TCA6408 I2C expander library for cluster addressing.
- `pcb/cluster-pcb`: cluster PCB KiCad project and documentation.
- `pcb/prism-pcb`: prism PCB KiCad project and documentation.
- `config/rigs`: local rig definitions for desk and full-rig testing.
- `logs`: hardware test logs and captured diagnostics. Keep generated logs out
  of git unless a specific log is intentionally preserved as documentation.

## Hardware Safety

- The desk rig is expected to have one cluster at address `10`.
- The full maze is expected to have seven clusters at addresses `10` through
  `16`, with seven prisms per cluster.
- Keep normal commanded positions within the firmware-safe range of `0..550 mm`.
- Use conservative post-home test targets unless a task explicitly requires a
  broader sweep.
- Do not run homing, movement, flashing, or power-cycle commands unless the user
  has made it clear that hardware interaction is intended.

## Current Hardware Debug Context

- The active bug is an intermittent post-home stationary prism: after homing,
  one or more prisms may stop responding to movement commands until reset or
  power cycle, while the rest of the prisms keep moving.
- The current desk test maze is a single cluster of seven prisms, expected at
  address `10`. It can be controlled over Ethernet by
  `software/hex_maze_interface_python` or reflashed over USB.
- The researcher workflow to reproduce is random repeated moves to positions up
  to about `400 mm`, followed by incremental homing passes. Each homing pass uses
  a `100 mm` home travel/home position so only prisms within the next `100 mm` of
  the hard stop complete that pass; repeated passes continue until every prism
  has hit the hard stop and homed.
- In several days, testing should expand to the full hex-maze: seven clusters,
  addresses `10..16`, seven prisms each, for `49` total prisms.
- Persistent investigation notes and the current test plan live in
  `docs/debugging/post-home-stationary-prism.md`.

## Useful Commands

- `make submodule-status`
- `make firmware-build`
- `make desk-verify`
- `make desk-smoke`
- `make desk-repeated-home`
- `make full-verify`
- `make full-smoke`

Hardware tests call into `software/hex_maze_interface_python`. Firmware builds
call into `firmware/ClusterController`.

## Change Boundaries

Commit source changes in the submodule that owns them first. Then update and
commit this superproject's submodule pointer so the tested multi-repo state is
reproducible.

For firmware/library debugging, prefer a local development build that uses the
checked-out submodule libraries. Once validated, update release pins in the
owning firmware repository deliberately.
