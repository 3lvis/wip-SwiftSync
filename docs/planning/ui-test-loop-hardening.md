# UI Test Loop Hardening

## Open items

- [ ] Extend the recovery path to erase or recreate the simulator after repeated runner-launch failures that survive a reboot-and-retry cycle.
- [ ] Determine whether package resolution noise in repeated `test-without-building` runs can be reduced further without destabilizing the loop.
