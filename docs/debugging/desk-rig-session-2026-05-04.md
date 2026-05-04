# Desk Rig Session 2026-05-04

## Rig

- Test rig: single cluster with seven prisms.
- Expected cluster address: `10`.
- Cluster IP: `192.168.10.10`.
- Host Ethernet interface: `enx00e04c19451d`.
- Host Ethernet address during test: `192.168.10.137/24`.
- USB serial target: `/dev/ttyACM0`.
- USB description: `W5500-EVB-Pico - Pico Serial`.
- USB hardware ID: `USB VID:PID=2E8A:1029 SER=E6625CA5633BB039`.

## Repository State Tested

Submodule state at the start of the session:

```text
firmware/ClusterController: 27b2179712b8a76265f8bbfb1a46b21155234853
libraries/TCA6408: 81bed8cecebe4c3f2ba5bb50b83e567aafc08f65
libraries/TMC51X0: 6df0d20b8f2dae76be31f0c78e7802bed5bfdcc5
pcb/cluster-pcb: 9cda192dd0e2a5332826be550fe63e21291cd07b
pcb/prism-pcb: 717e3fa59436f33d262e3b91072ff81ff6e1a8c7
software/hex_maze_interface_python: 542a6f13e7d7803eb17e536907f8913361b7d782
```

## Connectivity

Successful checks:

```sh
ping -c 2 -W 1 192.168.10.10
nc -vz -w 1 192.168.10.10 7777
pixi run maze --debug --timeout 1 communicating-cluster 10
pixi run maze --timeout 1 verify-cluster 10 --json
```

Observed:

- Ping had `0%` packet loss.
- TCP port `7777` was open.
- Protocol communication returned expected response bytes `04070278563412`.
- `verify-cluster 10 --json` returned `ok: true`.
- Address sweep with `verify-all-clusters` found only cluster `10`; clusters
  `11..16` did not respond, matching the desk rig.

## Non-Motion Commands

LED commands both returned `True`:

```sh
pixi run maze --timeout 1 led-on-cluster 10
pixi run maze --timeout 1 led-off-cluster 10
```

The LED was left off.

## Homing And Movement

Conservative homing command:

```sh
pixi run maze --timeout 1 home-cluster 10 250 20 50 10
```

Result:

- Command returned `True`.
- Home outcomes: all `stall`.
- Homed flags: `(1, 1, 1, 1, 1, 1, 1)`.
- Positions after home: `(0, 0, 0, 0, 0, 0, 0)`.

Conservative movement commands:

```sh
pixi run maze --timeout 1 write-targets-cluster 10 40 40 40 40 40 40 40
pixi run maze --timeout 1 read-positions-cluster 10
pixi run maze --timeout 1 write-targets-cluster 10 0 0 0 0 0 0 0
pixi run maze --timeout 1 read-positions-cluster 10
```

Result:

- Move to `40 mm` settled at `(40, 40, 40, 40, 40, 40, 40)`.
- Return to `0 mm` settled at `(0, 0, 0, 0, 0, 0, 0)`.
- Final verify after movement returned `ok: true`.

## Reset And Power-Cycle

Commands:

```sh
pixi run maze --timeout 1 reset-cluster 10
pixi run maze --timeout 1 verify-cluster 10 --json
pixi run maze --timeout 1 power-off-cluster 10
pixi run maze --timeout 1 verify-cluster 10 --json
pixi run maze --timeout 1 power-on-cluster 10
pixi run maze --timeout 1 verify-cluster 10 --json
```

Result:

- `reset-cluster 10` returned `True`.
- Network communication recovered after reset.
- After reset, homed flags cleared and positions initially read
  `(-1, -1, -1, -1, -1, -1, -1)`.
- `power-off-cluster 10` returned `True`; controller still responded.
- `power-on-cluster 10` returned `True`.
- Final verify after power-on returned `ok: true`.
- Final positions after power-on read `(0, 0, 0, 0, 0, 0, 0)`.

## Firmware Build And Flash

Build command:

```sh
cd firmware/ClusterController
pixi run build-rewrite
```

Result:

- Build succeeded for PlatformIO environment `pico-rewrite`.
- Firmware ELF/UF2 was generated under `.pio/build/pico-rewrite/`.
- Reported memory usage: `30.0%` RAM, `6.8%` flash.

Device discovery:

```sh
pixi run ports
```

Observed:

```text
/dev/ttyACM0
Hardware ID: USB VID:PID=2E8A:1029 SER=E6625CA5633BB039 LOCATION=1-2:1.0
Description: W5500-EVB-Pico - Pico Serial
```

Flash command:

```sh
pixi run flash-rewrite
```

Result:

- PlatformIO auto-detected `/dev/ttyACM0`.
- The RP2040 rebooted into BOOTSEL mode via 1200-baud open/close.
- Firmware loaded to flash and verified successfully.
- PlatformIO reported `Verifying Flash: OK`.
- The device rebooted and restarted the application.
- Post-flash `verify-cluster 10 --json` returned `ok: true`.

PlatformIO warned that `/etc/udev/rules.d/99-platformio-udev.rules` is
outdated. The helper script for updating those rules is:

```sh
bash docs/debugging/update-platformio-udev-rules.sh
```

## Final State

At the end of the session:

- Cluster `10` responded over the maze protocol at `192.168.10.10`.
- `verify-cluster 10 --json` returned `ok: true`.
- Positions read `(0, 0, 0, 0, 0, 0, 0)`.
- Homed flags were cleared after the firmware flash/reboot.
- Home outcomes read all `none`.
- `/dev/ttyACM0` was present as the W5500-EVB-Pico serial device.

Before commanding movement in the next session, home cluster `10` again.
