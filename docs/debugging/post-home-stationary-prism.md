# Post-Home Stationary Prism Debugging

## Symptom

Occasionally one prism does not move after a successful-looking cluster home,
while the other prisms move normally.

The stuck prism usually remains stuck until the cluster is reset or power
cycled. The issue is intermittent: the same workflow may pass many times before
one or more prisms fail to move after a home.

## Rigs

Desk test maze:

- one cluster
- seven prisms
- expected cluster address: `10`
- accessible over Ethernet through `software/hex_maze_interface_python`
- firmware can be reflashed over USB

Full hex-maze, available later:

- seven clusters
- expected cluster addresses: `10..16`
- seven prisms per cluster
- forty-nine prisms total

## Researcher Workflow To Reproduce

The failure workflow to model is:

1. Move all prisms repeatedly to random target positions.
2. Random targets may be as high as about `400 mm`.
3. Home incrementally using repeated home commands with a `100 mm`
   travel/home position.
4. The first home pass should only complete prisms already within `100 mm` of
   the hard stop.
5. The second pass should complete prisms that began roughly `100..200 mm` from
   the hard stop, and so on until all prisms hit the hard stop.
6. Command a normal post-home move and check whether every prism actually
   launches and reaches its target.

This is different from a single long-travel home command. Tests should keep the
incremental `100 mm` pass behavior unless deliberately isolating a variable.

## Current Lead

The desk rig has reproduced a related repeated-home bookkeeping inconsistency:

- `homed = false`
- `home_outcome = STALL`
- `position = 0`

That state has not always blocked the first post-home move on the desk rig, but
it is the best current lead for the full-rig failure.

## Reproduction Commands

Desk rig:

```sh
make desk-repeated-home
make desk-incremental-home-stress
```

Full rig, sequential per cluster:

```sh
make full-repeated-home
make full-incremental-home-stress
```

The incremental-home stress test matches the researcher workflow more closely:
random pre-home moves up to about `400 mm`, repeated homes with
`travel_limit = 100` until all prisms report homed, then a first post-home move
that records any prism that remains stationary. It writes generated JSONL logs
under `logs/`, which are intentionally ignored by git.

## Session Results

2026-05-05 desk-rig stress testing added
`hardware_incremental_home_stress_test.py` and ran `31` completed incremental
home trials on cluster `10`:

- random target range: `0..400 mm`
- completed random cluster moves: `91`
- repeated home travel limit: `100 mm`
- first post-home target: `40 mm`
- stationary-prism reproductions: `0`

Full run details are in `docs/debugging/desk-rig-session-2026-05-05.md`.

## Investigation Plan

### Phase 1: Desk Rig Reproduction

Goal: reproduce the exact intermittent failure on the single-cluster desk rig
without the added complexity of the full maze.

1. Confirm non-motion connectivity with `make desk-verify`.
2. Record the current submodule SHAs and firmware build artifact before motion
   testing.
3. Run a purpose-built incremental-home stress test on cluster `10`:
   random positions in `0..400 mm`, repeated `100 mm` home passes, and a
   conservative first post-home move.
4. Use deterministic random seeds and log every trial so a failing sequence can
   be replayed.
5. On failure, capture state before reset or power cycle:
   positions, homed flags, home outcomes, queued targets if available, paused
   state if available, controller parameters, run current, and communication
   status.
6. After capture, verify whether a normal movement command, another home pass,
   firmware reset, or power cycle is required to recover the prism.

### Phase 2: Instrumentation

Goal: distinguish a motion-driver state problem from firmware bookkeeping or
command-queue state.

Add temporary diagnostics only as needed, starting with per-prism firmware state
around homing completion and first post-home target dispatch:

- `homed_state`
- `home_active_state`
- `home_outcome_state`
- `paused_state`
- target queue depth and pending targets
- last commanded target
- actual position
- TMC ramp/motion mode if readable
- driver status/stall flags if readable

The important timestamps are before each `100 mm` home pass, immediately after
each pass completes, immediately before the first post-home move, immediately
after writing the post-home target, and while waiting for movement.

### Phase 3: Firmware Fix

Goal: make repeated incremental homing leave every prism in a state where the
next target command always launches.

Inspect and patch the homing and dispatch paths in
`firmware/ClusterController/firmware/rewrite_prism.cpp`, especially:

- `begin_home()`
- `complete_home_success()`
- `complete_home_failure()`
- `write_target()`
- queued target dispatch in `loop()`
- interactions between homing state, pause state, queued targets, and TMC ramp
  mode

Candidate bug classes to prove or rule out:

- a prism reaches stall but `homed_state` is cleared or never restored
- home completion leaves the prism paused or with a stale queued target
- a repeated home while already near zero leaves the TMC driver stopped in a
  mode that ignores the next target
- target writes after home are accepted by protocol but not dispatched to the
  affected prism
- stall/home outcome bookkeeping diverges from actual driver state

### Phase 4: Desk Rig Validation

Goal: prove the fix on the smallest rig before scaling out.

Run the exact failing seed if captured, then a longer desk soak:

- incremental-home stress test for many trials on cluster `10`
- existing `make desk-repeated-home`
- existing `make desk-smoke`
- a final conservative home and move check

Keep generated logs out of git unless a specific failure log is intentionally
preserved as documentation.

### Phase 5: Full Hex-Maze Validation

Goal: verify that the fix scales to all `49` prisms.

When the full rig is available:

1. Confirm addresses `10..16` respond with `make full-verify`.
2. Run the incremental-home stress test sequentially by cluster first.
3. If sequential tests pass, run a longer full-rig soak that cycles all clusters
   through random `0..400 mm` moves, repeated `100 mm` home passes, and first
   post-home movement checks.
4. Record per-cluster and per-prism failure rates, seeds, and recovery behavior.
5. Commit firmware/software changes in the owning submodules first, then update
   the superproject submodule pointers.

## Firmware Areas To Inspect

In `firmware/ClusterController/firmware/rewrite_prism.cpp`:

- `begin_home()`
- `complete_home_success()`
- `complete_home_failure()`
- `write_target()`
- queued target dispatch in `loop()`
- `homed_state`
- `home_active_state`
- `home_outcome_state`
- `paused_state`
- target queue counters

## Diagnostic Fields To Capture

For each prism, capture these before home, after home completion, immediately
after the first post-home target command, and during the first move:

- homed flag
- home active flag
- home outcome
- paused flag
- queue depth
- actual position
- target position
- ramp mode, if readable
- communication status

Keep temporary diagnostics in the firmware or Python interface until the issue
is understood. Once fixed, either remove them or document the debug command as a
supported protocol feature.
