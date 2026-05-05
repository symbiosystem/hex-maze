# Desk Rig Session 2026-05-05

## Purpose

Add and run a stress test that matches the researcher workflow for the
intermittent post-home stationary-prism bug:

1. Move the seven prisms on cluster `10` to repeated random positions.
2. Use random targets in the `0..400 mm` range.
3. Home with repeated `100 mm` travel-limit passes until every prism reports
   homed.
4. Command the first post-home move and detect any prism that remains
   stationary.

## Code Changes

- Added `software/hex_maze_interface_python/hardware_incremental_home_stress_test.py`.
- Made a formatting-only lint fix in
  `software/hex_maze_interface_python/hardware_repeated_home_test.py`.
- Added superproject Make targets:
  - `make desk-incremental-home-stress`
  - `make full-incremental-home-stress`
- Updated hardware Make targets to invoke `pixi run python` because this
  workspace does not have a bare `python` executable.
- Updated `docs/debugging/post-home-stationary-prism.md` with the new command.
- Updated `AGENTS.md` and `README.md` with the persistent bug context and
  active reproduction workflow.

The stress test writes JSONL logs under `logs/`, which are ignored by git.

## Verification

Software checks:

```sh
cd software/hex_maze_interface_python
python3 -m py_compile hardware_incremental_home_stress_test.py hardware_repeated_home_test.py
pixi run lint
pixi run test
```

Results:

- Python compile passed.
- Ruff passed.
- Pytest passed: `12 passed`.

Initial non-motion verify:

```sh
pixi run maze --timeout 1 verify-cluster 10 --json
```

Result:

- `ok: true`
- cluster `10` communicating
- positions: `(0, 0, 0, 0, 0, 0, 0)`
- homed flags: `(0, 0, 0, 0, 0, 0, 0)`
- controller parameters at defaults

Two initial stress-test invocations failed before motion because the sandbox
blocked raw Python TCP access. The approved command prefix for hardware stress
tests is:

```sh
pixi run python hardware_incremental_home_stress_test.py
```

## Hardware Stress Runs

Short validation run:

```sh
pixi run python hardware_incremental_home_stress_test.py \
  --cluster 10 \
  --trial-count 1 \
  --random-move-count 1
```

Result:

- `ok: true`
- log: `logs/incremental_home_stress_20260505_094857.jsonl`
- random targets: `(125, 166, 383, 306, 393, 225, 246)`
- incremental home passes: `5`
- post-home target: `40 mm`
- stationary prisms after home: none

Ten-trial run:

```sh
pixi run python hardware_incremental_home_stress_test.py \
  --cluster 10 \
  --trial-count 10 \
  --random-move-count 3
```

Result:

- `ok: true`
- log: `logs/incremental_home_stress_20260505_095147.jsonl`
- trials: `10`
- random cluster moves: `30`
- max random target: `399 mm`
- max observed random position: `397 mm`
- home passes per trial: `(5, 3, 4, 4, 4, 5, 4, 4, 4, 3)`
- stationary prisms after home: none

Twenty-trial soak:

```sh
pixi run python hardware_incremental_home_stress_test.py \
  --cluster 10 \
  --trial-count 20 \
  --random-move-count 3 \
  --compact-output
```

Result:

- `ok: true`
- log: `logs/incremental_home_stress_20260505_095932.jsonl`
- trials: `20`
- random cluster moves: `60`
- max random target: `400 mm`
- max observed random position: `398 mm`
- home passes per trial:
  `(4, 3, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4)`
- stationary prisms after home: none

Total stress coverage for this session:

- completed incremental-home trials: `31`
- completed random cluster moves: `91`
- post-home stationary-prism reproductions: `0`

## Final State

The stress test temporarily wrote faster controller parameters. They were
restored to defaults with:

```sh
pixi run maze --timeout 1 write-controller-parameters-cluster 10 1 5 10 20 40 20 30 50
```

Final verify:

```sh
pixi run maze --timeout 1 verify-cluster 10 --json
```

Result:

- `ok: true`
- cluster `10` communicating
- homed flags: `(1, 1, 1, 1, 1, 1, 1)`
- positions: `(40, 40, 40, 40, 40, 40, 40)`
- run current: `75%`
- controller parameters restored to defaults:
  `(1, 5, 10, 20, 40, 20, 30, 50)`

## Notes

The desk rig did not reproduce the stuck-prism failure in this session. The new
stress test is ready for longer desk soaks and sequential full-rig testing when
clusters `10..16` are available.

## Commit Handoff

Commit source changes in the owning submodule first:

```sh
cd software/hex_maze_interface_python
git status --short
git add hardware_incremental_home_stress_test.py hardware_repeated_home_test.py
git commit -m "test: add incremental home stress runner"
git push
```

Then commit the superproject documentation, Makefile changes, and updated
submodule pointer:

```sh
cd /home/peter/Repositories/symbiosystem/hex-maze
git status --short
git add AGENTS.md README.md Makefile docs/debugging/post-home-stationary-prism.md docs/debugging/desk-rig-session-2026-05-05.md software/hex_maze_interface_python
git commit -m "docs: capture post-home stress test workflow"
git push
```

Generated files under `logs/` are ignored and should not be committed unless a
specific failure log is intentionally preserved as documentation.

## New Session Handoff

Starting state after this session:

- desk rig: one cluster, address `10`
- final cluster verify: `ok: true`
- final positions: `(40, 40, 40, 40, 40, 40, 40)`
- final homed flags: `(1, 1, 1, 1, 1, 1, 1)`
- run current: `75%`
- controller parameters restored to defaults:
  `(1, 5, 10, 20, 40, 20, 30, 50)`

Useful continuation commands:

```sh
make desk-verify
make desk-incremental-home-stress
```

For a longer desk soak:

```sh
cd software/hex_maze_interface_python
pixi run python hardware_incremental_home_stress_test.py \
  --cluster 10 \
  --trial-count 100 \
  --random-move-count 3 \
  --compact-output
```

When the full rig is available:

```sh
make full-verify
make full-incremental-home-stress
```

If the stress test fails, do not reset or power cycle immediately. The runner
stops on the first failure and records the failure snapshot in its JSONL log.
Inspect positions, homed flags, home outcomes, controller parameters, and the
reported stationary prism list before attempting recovery.
