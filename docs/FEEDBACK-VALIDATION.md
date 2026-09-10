# Feedback-pass validation checklist

Validates the 2026-09-08 feedback pass (branch `ghostlight-feedback-pass`) against `UxeaHalloweenFeedback.md`.
Local checks already pass: 9 scripts compile, 10 rule groups pass, packaged sources match.
Everything below needs Roblox Studio with Play running. Fill in the Results section at the bottom.

## Part A. Automated acceptance run (about 90 seconds)

1. Open `build/GhostlightHollow.Acceptance.rbxlx` (rebuilt 2026-09-09 08:14, matches current sources).
2. View menu, Output. Type `ACCEPTANCE` in the Output filter box.
3. Press **Play (F5)**, not Run (F8). The runner needs a client.
4. Do nothing. The test teleports and drives your character itself.

Expected: 26 lines beginning `ACCEPTANCE PASS:` and then
`ACCEPTANCE COMPLETE: 26 checks passed.` The 3rd line should now read
`seven plots and six mansion areas created with mansion path clear`.

A failure prints one orange warning containing `ACCEPTANCE FAIL: <check name>` and stops.
Copy the whole warning and any red errors above it. Also note whether the HUD ever went blank.

This place makes you invulnerable and grants a billion dollars. Do not judge balance or feel here.

## Part B. Manual checks in the shipped place

Open `build/GhostlightHollow.rbxlx`, Play, wait for the HUD. Each row: what was built, then what to look for.

### Spawn and town
- [ ] **HUD layout.** One stats box top-left (money, $/sec with bonus, vacuum count, rebirths), a vertical
  nav column under it (HAUNT, COLLECTION, MANSION, UPGRADES, REBIRTH), action buttons bottom-right.
  Nothing across the top of the screen. The objective line above the stats box must not touch the box.
- [ ] **Movement.** You should feel noticeably quicker than stock Roblox. Base is 22 (stock 16).
- [ ] **Chamber portal at spawn.** A cyan glowing arch directly ahead of spawn on a round stone base,
  bobbing slightly and pulsing its light. Prompt reads "Enter chamber". With no ghosts placed it
  should refuse with a toast, not enter.
- [ ] **Welcome sign vs portal.** The GHOSTLIGHT HOLLOW sign stands 5 studs in front of the portal, over
  its base. Does it block the view of the portal or its prompt? Judge whether it should move.
- [ ] **Rebirth altar.** Right side of the plaza: marble round base, purple neon pedestal, floating amber
  orb with a light. Prompt on the orb reads "View rebirth" and opens the Rebirth panel.
- [ ] **Vibrancy.** Neon parts, windows and lanterns should read as glowing, not blown out. Bloom is low.
  Compare the lamp posts and the mansion windows against the dark sky. Note anything that hurts to look at.

### Haunt plot
- [ ] **Mansion path clear.** Walking from the plaza to the mansion, no Haunt plot sits on the wide path.
  Seven plots ring the town, not eight.
- [ ] **Plot size and detail.** Each plot is a roofed hall with pillars, side walls, a back wall, an owner
  board, 20 slot pads in a 5 by 4 grid, and a glowing deposit pad. Pads beyond your slot count are dimmed.
- [ ] **Income hologram.** Floating cyan text above the centre of your plot: `$/SEC • $N` and
  `N active haunt ghosts`. It updates every second and changes when you place or remove a ghost.
  Note: it shows the Haunt total, not a per-ghost value. The per-ghost figure is in the HAUNT panel rows.
- [ ] **Inventory and selector.** HAUNT panel lists each placed slot with a 3D ghost icon, its $/sec and a
  REMOVE button, then every spare owned ghost with a PLACE button. COLLECTION shows all 14 ghosts with
  icons for discovered ones and grey UNDISCOVERED rows for the rest.
- [ ] **Deposit.** Depositing auto-fills empty slots with the highest-income ghosts you own.

### Hunting (Abandoned Foyer)
- [ ] **Room lights.** No light switches anywhere. Candles on six tables give fixed warm light, one
  flickers every few seconds. Your own flashlight still toggles with F. Dark corners stay navigable.
- [ ] **Rooms.** Floor is 132 by 112 with four divider walls forming separate bays, three named room
  signs on the back wall, tables and candles, plus floor-specific props (beds on 2, books on 3,
  sarcophagi on 5 and 6). Decide whether this reads as "specific areas" or still one big room.
- [ ] **Continuous suction.** While the bar fills, the ghost shrinks steadily (to about two thirds at full)
  and its glow brightens. It must not stay full size until the end.
- [ ] **Finale.** At 100% a copy of the ghost spirals and shrinks into the nozzle over about two thirds
  of a second, then the rarity toast appears.
- [ ] **Click pulse.** Each click bounces the TAP TO VACUUM button bottom-right. This is the "click
  animation" item. Decide whether it is enough or whether you wanted an on-ghost prompt.
- [ ] **Ghost attacks.** While you are within 12 studs of a ghost you are capturing, every 4.5 seconds:
  red toast `THE <NAME> STRIKES!`, your health drops by 7, and the capture bar loses about 6 points.
  The bar text says "MOVE TO AVOID THE ATTACK", but there is no wind-up and the hit already landed.
  Note whether that text feels like a lie. Check that dying mid-capture respawns you in town with the
  vacuum re-equipped and no stuck beam.
- [ ] **Resistance.** Ghost surges away (bar turns amber, "PULLING AWAY"), then drifts back toward you.
  Standing still and clicking should still work for commons. Walking more than 38 studs away or pausing
  clicks for 2.5 seconds breaks the beam with a toast.

### Economy (read the numbers, do not grind)
- [ ] **Shop prices.** UPGRADES panel: Flashlight $8.0K, Movement $10.0K, Capacity $12.0K, Suction
  $15.0K, Capture $20.0K at level 1. Haunt level 2 $150.0K.
- [ ] **Floor prices.** MANSION panel: Bedrooms $350.0K, Library $3.50M, Basement $35.00M,
  Crypt $350.00M, Catacombs $2.50B.
- [ ] **Rebirth.** REBIRTH panel: requires all six areas and $5.00B, next bonus 1.5x.
- [ ] **Ghost income.** COLLECTION: Mothlight $3/sec, Teacup Trembler $4, Lantern Lurker $10 ... Door to
  Nowhere $32.5K. Five commons at start earn roughly $15 to $20 per second.

Rough idle times implied by those numbers, for your judgement on "not so easy":

| Milestone | Cost | Time at typical early income |
|---|---|---|
| First upgrade (Flashlight) | $8K | 5 to 8 minutes |
| Haunt level 2 | $150K | about 1 hour |
| Whispering Bedrooms | $350K | about 2 hours |
| Cursed Library | $3.5M | 3 to 4 hours after Bedrooms |
| First rebirth (rule-test optimistic sim) | $5B | about 80 hours idle |

### Chamber and rebirth
- [ ] Enter the portal with at least one ghost placed. Camera goes top-down over a miniature four-room
  house. Your placed ghosts drift around, then converge on a prey ghost in the last 8 seconds of each
  35-second cycle. A "YOUR GHOSTS FOUND ..." toast and a money bump follow. EXIT restores the camera.
- [ ] The HAUNT panel's CHAMBER button still works from home as a second entrance. Decide whether to keep it.

## Part C. Defects predicted from reading the code (please confirm or clear)

1. **Rebirth altar overlaps the old sign.** The old REBIRTH ALTAR sign and the new altar pedestal are
   built at the same spot. Expect z-fighting geometry and two labels stacked, plus the ORIN caretaker
   label nearby. See the `W.Rebirth=sign` and `W.RebirthAltar=part` lines in `src/server/World.luau`.
2. **Eighth player gets kicked.** Only seven plots exist now but server size is still 8 and the kick
   message still says "All eight Haunts are occupied". Set server size to 7 or add a plot elsewhere.
   The startup print also still says "eight Haunts".
3. **Phone landscape nav overflow.** The left nav is a fixed 310 pixels starting at y 270. On 844 by 390
   the UPGRADES and REBIRTH buttons fall off the bottom of the screen.
4. **Attack text promises a dodge that does not exist.** See Ghost attacks above.
5. **Hologram is per-Haunt, not per-ghost.** See Income hologram above.
6. **Objective text can touch the stats box** when it wraps to two lines.
7. **FIXED 2026-09-09 evening: every nav panel opened empty.** Studio logged `Main:112` and `Main:83`
   "attempt to index nil with 'Visible'". The panel renderer referenced `actions` and `captureBox` before
   those locals were declared, so they were nil globals. Declarations moved above the renderer, and
   `tools/verify.py` now runs `tools/lint_luau.py`, which fails the build on this class of bug and on
   unknown globals. Re-test: open HAUNT, MANSION, UPGRADES, REBIRTH and confirm each lists rows.
8. **FIXED 2026-09-09 evening: flaky acceptance check 19.** The fixture now polls for each expected
   state (up to 6 s) instead of waiting a fixed 0.5 s. Re-test: run the Acceptance place twice.

## Part D. Device emulation (Studio Test tab, Device dropdown)

- [ ] Phone portrait 390 by 844: panel fits, nav column readable, action buttons do not cover an open panel.
- [ ] Phone landscape 844 by 390: confirm or clear defect 3.
- [ ] Tablet: nothing overlapping, capture bar visible while a panel is closed.
- [ ] Desktop 1920 by 1080: no Roblox backpack hotbar visible (it is disabled on purpose).

## Results

Date:
Acceptance run: ___ / 26 passed. Failing check and error text:

Confirmed defects (number from Part C, plus anything new):

Feel notes (movement, attacks, suction, vibrancy):

Balance verdict (too easy / about right / too grindy) and which milestone felt wrong:
