# Post-Home Stationary Prism Debugging

## Symptom

Occasionally one prism does not move after a successful-looking cluster home,
while the other prisms move normally.

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
```

Full rig, sequential per cluster:

```sh
make full-repeated-home
```

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
