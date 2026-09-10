# CODEX: BUILD THE GAME — DO NOT JUST DESCRIBE IT

You are Codex working directly on a Roblox game project.

Your job is to **ACTUALLY BUILD THIS GAME IN THE PROJECT**, not just explain how to build it and not just generate a design document.

You have access to the project files. Inspect the existing project structure first, understand what already exists, and then create/modify the necessary Roblox Lua/Luau scripts, instances, UI, models/placeholders, systems, and configuration needed to make the game playable.

If something does not exist yet, CREATE IT.

If something is broken, FIX IT.

If there are existing systems that conflict with this design, modify them appropriately.

After implementing each major system, test the code for errors and fix them before moving on.

Do not stop after creating a few scripts.

The end goal is a **PLAYABLE ROBLOX GAME** with a functioning gameplay loop.

---

# GAME: GHOST HUNTING SIMULATOR / TYCOON

The game is a spooky Roblox Ghost Hunting Simulator / Tycoon.

The player personally enters a Haunted Mansion and hunts ghosts using a Ghostbusters-style vacuum.

The player finds ghosts, fights their resistance, sucks them into the vacuum, captures them, returns home, places them in their Haunt, and uses the ghosts to generate passive dollars.

The player's captured ghosts also become useful inside an AFK feature called the **Haunt Chamber**, where the player's ghosts autonomously hunt while the player watches from a top-down camera.

The game must be simple and easy to understand.

The central gameplay loop is:

**SPAWN IN TOWN**

↓

**GO TO YOUR HAUNT**

↓

**ENTER THE HAUNTED MANSION**

↓

**PERSONALLY HUNT GHOSTS**

↓

**FIND A GHOST**

↓

**AIM / CLICK THE GHOST**

↓

**VACUUM STARTS SUCKING IT**

↓

**SPAM CLICK TO INCREASE CAPTURE POWER**

↓

**GHOST RESISTS AND PULLS AWAY**

↓

**PLAYER CHASES IT**

↓

**KEEP SUCKING IT IN**

↓

**GHOST GETS SUCKED INTO THE VACUUM**

↓

**GHOST CAPTURED**

↓

**RETURN TO HAUNT**

↓

**PLACE GHOST IN HAUNT**

↓

**GHOST GENERATES $/SEC**

↓

**SPEND $ ON UPGRADES**

↓

**UNLOCK DEEPER MANSION AREAS**

↓

**HUNT RARER GHOSTS**

↓

**EARN MORE $/SEC**

↓

**REBIRTH**

↓

**REPEAT**

This loop is the foundation of the entire game.

---

# IMPORTANT DESIGN RULE

The player is the ghost hunter.

The player personally performs the active hunting.

Captured ghosts are NOT traditional combat pets.

Captured ghosts are primarily:

1. Collectibles
2. Haunt income generators
3. AFK Haunt Chamber hunters

Do not turn the ghosts into complicated RPG companions.

Do not add unnecessary currencies.

The primary currency is simply:

**$**

Do NOT create ectoplasm, souls, spirit energy, crystals, shards, fear points, or other currencies.

Keep the economy simple.

---

# STEP 1 — INSPECT THE PROJECT

Before building:

1. Inspect the entire existing project structure.
2. Identify whether this is a Roblox Studio project / Rojo-style project / another Roblox codebase.
3. Identify existing ServerScriptService, ReplicatedStorage, StarterGui, StarterPlayer, Workspace, and other relevant structures.
4. Reuse existing systems where appropriate.
5. Do not unnecessarily destroy working code.
6. Create a clean structure for the new game systems.

Use modular Luau code.

Keep server-authoritative logic on the server.

The client should never be trusted with:

- Money
- Ghost ownership
- Capture rewards
- Rebirths
- Inventory
- $/sec
- Unlocks

---

# STEP 2 — BUILD THE SPOOKY TOWN

Create the main spawn town.

The player should spawn in a small spooky town.

The town should contain:

- Central circular plaza
- Player Haunt plots around the plaza
- Paths connecting the Haunts
- Main path leading to the Haunted Mansion
- Rebirth area
- Upgrade area
- Leaderboard area
- Simple spooky buildings
- Graveyard
- Trees
- Fog
- Lamps
- Lanterns
- Small NPCs
- Signs

The map does NOT need to be enormous.

The important locations must be obvious.

The player should immediately understand:

**THIS IS MY HAUNT**

and

**THAT IS THE HAUNTED MANSION**

Build the environment using Roblox-compatible parts/models/placeholders where necessary.

Prioritize functionality over extremely detailed art.

---

# STEP 3 — PLAYER HAUNTS

Create individual Haunt plots around the town.

Support multiple players having their own Haunt simultaneously.

Each player should automatically receive an available Haunt.

A Haunt contains:

- Haunted house
- Ghost display areas
- Ghost slots
- Income display
- Haunt upgrade area
- Haunt Chamber entrance

Players should be able to walk into other players' Haunts.

Other players can see the ghosts displayed there.

The Haunt is a social showcase.

---

# STEP 4 — HAUNT GHOST SLOTS

Create a simple slot system.

Example:

Haunt Level 1:
5 slots

Haunt Level 2:
8 slots

Haunt Level 3:
12 slots

Haunt Level 4:
16 slots

Haunt Level 5:
20 slots

Use reasonable values and make them configurable.

Players can place captured ghosts into available slots.

Players can remove/replace ghosts.

The player should clearly see:

**Ghosts: 5/8**

and:

**$/SEC: $1,250**

---

# STEP 5 — GHOST DATA SYSTEM

Create a centralized GhostData configuration/module.

Every ghost should contain data such as:

- Unique ID
- Name
- Rarity
- Base income per second
- Capture difficulty
- Mansion areas where it can spawn
- Visual/model reference
- Spawn weight

Example rarities:

Common
Uncommon
Rare
Epic
Legendary
Mythic
Secret

Create an initial roster of multiple ghosts for every rarity.

Use unique names and unique visual designs.

Do not make every ghost just a recolored version of another ghost.

Use different shapes and concepts.

Examples could include:

- Wisp
- Poltergeist
- Phantom
- Shadow
- Possessed Doll
- Floating Childlike Spirit
- Headless Ghost
- Grim Specter
- Cursed Knight
- Ancient Spirit

Create original names/designs rather than copying existing games.

---

# STEP 6 — THE PLAYER'S VACUUM

Create the player's main ghost-catching tool.

It should be a Ghostbusters-style vacuum/trap device.

The player should visibly hold it.

It should contain:

- Vacuum body
- Hose
- Nozzle
- Capture container
- Flashlight attachment
- Suction effects
- Upgradeable stats

This is the player's primary gameplay tool.

The vacuum must actually function.

---

# STEP 7 — ACTIVE GHOST HUNTING

THIS IS THE MOST IMPORTANT GAMEPLAY SYSTEM.

When the player enters the Haunted Mansion, they personally hunt ghosts.

Ghosts should spawn inside the Mansion.

They should wander around.

They should not simply stand still waiting for the player.

Ghosts can:

- Float around rooms
- Move through hallways
- Hide
- Move behind objects
- Disappear/reappear
- Fly through walls
- Wander between rooms
- Flee when approached

Keep the AI relatively simple and performant.

---

# STEP 8 — VACUUM TARGETING

When the player aims at a ghost and clicks/interacts with it:

Start the capture process.

The vacuum should:

- Point toward the ghost
- Create a visible suction beam/effect
- Pull the ghost toward the nozzle
- Play suction audio
- Animate the ghost being pulled toward the player

Do NOT instantly capture the ghost.

The player must actively fight to capture it.

---

# STEP 9 — SPAM CLICK CAPTURE MECHANIC

The player must **spam click** while capturing the ghost.

Every successful click contributes capture power.

Example:

CAPTURE POWER

`██████░░░░`

The more the player clicks, the stronger the suction becomes.

The ghost should visibly move closer as capture progress increases.

This needs to feel interactive.

The player should physically feel like they are pulling the ghost into the vacuum.

Do not make it a passive timer.

The player's clicking should matter.

---

# STEP 10 — GHOST RESISTANCE

Ghosts actively resist capture.

While being vacuumed:

The ghost should:

- Pull backward
- Fly away
- Shake
- Move side to side
- Fight against the suction
- Try to escape
- Break the player's capture if it gets far enough away

The player should have to follow it.

Example gameplay:

Player locks onto ghost.

↓

Ghost gets pulled toward vacuum.

↓

Ghost suddenly fights back.

↓

Ghost flies backward.

↓

Player follows it.

↓

Player keeps clicking.

↓

Vacuum gets stronger.

↓

Ghost gets closer.

↓

Ghost fights again.

↓

Player finally overpowers it.

↓

Ghost gets sucked into the vacuum.

This should be the signature gameplay mechanic.

---

# STEP 11 — CAPTURE DIFFICULTY

Make rarity affect capture difficulty.

Example:

Common:
Very easy

Uncommon:
Easy

Rare:
Moderate

Epic:
Difficult

Legendary:
Very difficult

Mythic:
Extremely difficult

Secret:
Extremely rare and difficult

Create configurable capture resistance values.

Do not make rare ghosts impossible.

The player should feel:

**"That was hard, but I caught it!"**

---

# STEP 12 — FULL SUCTION ANIMATION

When capture reaches 100%:

The ghost should be visibly sucked completely into the vacuum.

Animation sequence:

1. Ghost gets pulled toward nozzle.
2. Ghost struggles.
3. Ghost becomes increasingly compressed/distorted.
4. Suction particles accelerate.
5. Ghost is pulled rapidly into the nozzle.
6. Ghost disappears into the vacuum.
7. Vacuum makes a strong capture sound.
8. Screen/UI displays the result.
9. Ghost is added to the player's inventory.

Example:

**GHOST CAPTURED!**

**LEGENDARY**

**Phantom Knight**

The actual ghost model should visibly disappear into the vacuum.

Do not simply remove the ghost with no visual feedback.

---

# STEP 13 — FLASHLIGHT

The Mansion should be spooky.

Every player should have a flashlight.

The flashlight can be toggled:

**ON / OFF**

It should illuminate the environment around the player.

Make the flashlight useful.

Some areas should be very dark.

The player should use their flashlight to find ghosts.

Potential visual moments:

The player walks through darkness.

The flashlight reveals a ghost.

The player looks away.

The ghost disappears.

The player hears a sound.

They turn around.

The ghost is behind them.

Then the hunting begins.

---

# STEP 14 — MANSION LIGHTING

Create interactive lights inside the Mansion.

Some lights can be turned on.

Use:

- Light switches
- Lamps
- Ceiling lights
- Flickering bulbs
- Candles
- Emergency lights
- Broken lights

Some rooms can have working lights.

Some should remain dark.

Do not create a separate electricity currency.

Lighting is purely an exploration / atmosphere mechanic.

---

# STEP 15 — SPOOKY MANSION ATMOSPHERE

The Mansion should feel genuinely spooky without becoming a hardcore horror game.

Use:

- Fog
- Shadows
- Darkness
- Flickering lights
- Dust
- Cobwebs
- Abandoned furniture
- Broken windows
- Portraits
- Old books
- Candles
- Strange objects
- Ambient sounds
- Wind
- Footsteps
- Door sounds
- Distant noises

The player should feel curiosity and tension while exploring.

Do not make everything pitch black.

Players must still be able to see and play.

---

# STEP 16 — MANSION FLOORS

Create multiple progressively harder areas.

Example:

## FLOOR 1 — ABANDONED FOYER

Common
Uncommon
Rare

Easy ghosts.

## FLOOR 2 — HAUNTED BEDROOMS

Uncommon
Rare
Epic

More darkness.

## FLOOR 3 — CURSED LIBRARY

Rare
Epic
Legendary

Large rooms and hiding ghosts.

## FLOOR 4 — FORGOTTEN BASEMENT

Epic
Legendary
Mythic

Very dark.

Flashlight becomes important.

## FLOOR 5 — THE CRYPT

Legendary
Mythic
Secret

Very spooky.

## FLOOR 6 — THE CATACOMBS

Mythic
Secret

Endgame.

These are examples.

You may improve the themes, but maintain the same progression concept.

---

# STEP 17 — MANSION UNLOCKS

Players use dollars to unlock deeper Mansion floors.

Example:

Floor 1:
Free

Floor 2:
$25,000

Floor 3:
$250,000

Floor 4:
$2,500,000

Floor 5:
$25,000,000

Floor 6:
$250,000,000

Balance these values around actual testing.

The player should always have a clear next goal.

---

# STEP 18 — GHOST COLLECTION

Captured ghosts permanently enter the player's collection.

The collection should show:

- Ghost name
- Rarity
- Model/image
- $/sec
- Owned quantity
- Discovered/not discovered

The collection should feel rewarding.

Players should want to discover every ghost.

Do not make the collection system overly complicated.

---

# STEP 19 — HAUNT INCOME

Captured ghosts can be placed inside the player's Haunt.

Each ghost generates passive dollars.

Example:

Common:
$5/sec

Uncommon:
$15/sec

Rare:
$50/sec

Epic:
$200/sec

Legendary:
$1,000/sec

Mythic:
$5,000/sec

Secret:
Very high income

These are starting examples.

Balance the economy through testing.

The important rule is:

**BETTER GHOST = MORE $/SEC**

Display the total income prominently.

Example:

**$3,250/sec**

Money should accumulate automatically.

---

# STEP 20 — GHOSTS ARE PASSIVE ASSETS

Once a ghost is captured, it does NOT become a combat pet.

Its normal gameplay purpose is:

**Collection + Haunt Income**

Its second gameplay purpose is:

**Haunt Chamber AFK Hunting**

Do not create complicated abilities for every ghost.

Do not make the player send ghosts into combat during normal gameplay.

The player hunts.

The ghosts generate money.

---

# STEP 21 — HAUNT UPGRADES

Players can spend dollars upgrading their Haunt.

The primary benefit should be more ghost slots.

Example:

Level 1:
5 slots

Level 2:
8 slots

Level 3:
12 slots

Level 4:
16 slots

Level 5:
20 slots

The Haunt should also visually improve as it levels up.

For example:

Small Haunted House

↓

Large Haunted House

↓

Haunted Manor

↓

Haunted Estate

↓

Massive Haunted Mansion

Keep the upgrade system simple.

---

# STEP 22 — VACUUM UPGRADES

Create a simple upgrade system for the player's hunting equipment.

### SUCTION POWER

Higher suction pulls ghosts toward the player faster.

### CAPTURE POWER

Requires fewer clicks to capture ghosts.

### VACUUM CAPACITY

Allows more captured ghosts before returning home.

### MOVEMENT SPEED

Allows faster exploration.

### FLASHLIGHT

Improves visibility/range.

Each upgrade should have a clear benefit.

The player should always have something useful to spend dollars on.

---

# STEP 23 — VACUUM CAPACITY

Give the vacuum a limited capacity.

Example:

Level 1:
3 ghosts

Level 2:
5 ghosts

Level 3:
8 ghosts

Level 4:
12 ghosts

When the vacuum is full:

**VACUUM FULL**

The player should return to their Haunt and deposit the ghosts.

If playtesting shows this creates unnecessary downtime, increase capacity.

Do not make walking back and forth frustrating.

---

# STEP 24 — MONEY LOOP

Money comes primarily from ghosts in the Haunt.

The player uses money to:

- Upgrade vacuum
- Upgrade capture power
- Upgrade movement
- Upgrade flashlight
- Increase Haunt slots
- Unlock Mansion floors
- Rebirth

The player should constantly have a reason to earn more dollars.

---

# STEP 25 — REBIRTH

Create a simple Rebirth system.

When the player reaches the required progression:

They can Rebirth.

Rebirth resets temporary progression:

- Money
- Mansion unlocks
- Vacuum upgrades
- Haunt upgrades

Rebirth keeps:

- Ghost collection
- Discovered ghosts
- Rebirth count
- Permanent income multiplier

Example:

0 Rebirths:
1x

1 Rebirth:
1.5x

2 Rebirths:
2x

3 Rebirths:
2.5x

Balance these values through testing.

The point of rebirth is:

**RESET → PERMANENT BONUS → FASTER PROGRESSION**

---

# STEP 26 — HAUNT CHAMBER

Create the AFK feature called:

**HAUNT CHAMBER**

This is a separate experience from active hunting.

When the player enters the Haunt Chamber:

Change the camera to an elevated top-down / isometric-style view.

Show a miniature haunted mansion.

The player's equipped/placed ghosts appear inside.

Those ghosts autonomously hunt.

They should:

- Walk through rooms
- Search
- Find ghosts
- Capture ghosts
- Move around
- Occasionally discover rare ghosts
- Generate rewards

The player watches their ghosts hunting for them.

---

# STEP 27 — HAUNT CHAMBER REWARDS

Use the existing game systems.

Do NOT create another currency.

Use:

**$**

and:

**Ghost Collection**

Example UI:

**HAUNTING IN PROGRESS**

Ghosts Hunting: 5

Current Income: $4,250/sec

Discoveries: 23

Occasional notification:

**YOUR GHOSTS FOUND A RARE GHOST!**

This should be simple.

---

# STEP 28 — ACTIVE HUNTING VS AFK

These must feel like two different gameplay modes.

### ACTIVE

The player personally:

- Explores
- Uses flashlight
- Finds ghosts
- Uses vacuum
- Spams click
- Fights resistance
- Chases ghosts
- Captures them

### AFK

The player's ghosts:

- Explore
- Hunt
- Discover
- Generate rewards

This distinction is extremely important.

The player should feel like a real ghost hunter when actively playing.

---

# STEP 29 — SOCIAL HAUNTS

Players can visit other players' Haunts.

Show:

- Ghost collection
- Rarest ghost
- Haunt level
- $/sec
- Rebirth count

Rare ghosts should visually stand out.

A Secret ghost should be an obvious flex.

---

# STEP 30 — UI

Create a clean Roblox-style interface.

Main HUD:

**$ MONEY**

**$/SEC**

**REBIRTHS**

Buttons:

**HAUNT**

**COLLECTION**

**MANSION**

**UPGRADES**

**REBIRTH**

During active hunting show:

**CAPTURE POWER**

when capturing.

Also show:

**VACUUM: 2/5**

Keep the interface mobile-friendly.

Do not clutter the screen.

---

# STEP 31 — GHOST CAPTURE FEEDBACK

Every successful capture should feel rewarding.

Use:

- Sound
- UI animation
- Particles
- Rarity text
- Ghost name
- Capture animation
- Small camera feedback where appropriate

A rare capture should feel significantly more exciting than a Common capture.

For example:

**LEGENDARY GHOST CAPTURED!**

should have a much stronger presentation than:

**COMMON GHOST CAPTURED!**

---

# STEP 32 — SOUND

Add appropriate sounds where possible.

Important sounds:

- Vacuum idle
- Vacuum suction
- Strong suction
- Ghost resistance
- Ghost escape
- Ghost capture
- Rare discovery
- Footsteps
- Doors
- Lights
- Ambient Mansion sounds

The Mansion should sometimes be quiet.

Use silence and subtle sounds to create atmosphere.

---

# STEP 33 — DATA SAVING

Implement reliable server-side persistence.

Save:

- Money
- Ghost collection
- Ghost quantities
- Equipped ghosts
- Haunt level
- Mansion unlocks
- Vacuum upgrades
- Movement upgrades
- Flashlight upgrades
- Capture upgrades
- Vacuum capacity
- Rebirth count
- Permanent multipliers

Make saving robust.

Handle player leaving safely.

Handle loading safely.

Do not duplicate rewards.

Do not allow client-side exploits to give money or ghosts.

---

# STEP 34 — PERFORMANCE

The game must be designed to support multiple players.

Avoid unnecessarily expensive loops.

Ghost AI should be efficient.

Do not run expensive calculations every frame on the server if they are not necessary.

Use appropriate RemoteEvents/RemoteFunctions.

Validate all client requests server-side.

Keep the game playable on lower-end Roblox devices.

---

# STEP 35 — DEVELOPMENT ORDER

Do NOT attempt to polish everything at once.

Build in this order:

## PHASE 1 — CORE HUNTING

Build and test:

- Vacuum
- Ghost spawning
- Ghost movement
- Targeting
- Click capture
- Spam clicking
- Capture meter
- Ghost resistance
- Ghost escape
- Suction animation
- Ghost capture
- Collection

This must work before anything else.

## PHASE 2 — MANSION

Build:

- Mansion
- Rooms
- Floors
- Ghost spawn zones
- Flashlight
- Lights
- Spooky atmosphere
- Mansion progression

## PHASE 3 — HAUNT

Build:

- Player Haunts
- Ghost slots
- Ghost placement
- $/sec
- Money
- Haunt upgrades

## PHASE 4 — ECONOMY / UPGRADES

Build:

- Vacuum upgrades
- Movement
- Flashlight
- Capacity
- Mansion unlocks

## PHASE 5 — REBIRTH

Build:

- Rebirth UI
- Requirements
- Reset
- Permanent multiplier

## PHASE 6 — HAUNT CHAMBER

Build:

- Top-down camera
- Ghost autonomous movement
- Autonomous hunting
- Discoveries
- Rewards

## PHASE 7 — SOCIAL / POLISH

Build:

- Other player Haunts
- Leaderboards
- Better UI
- Effects
- Sounds
- Animations
- Environment polish

---

# STEP 36 — TEST THE COMPLETE LOOP

Once the systems are implemented, test the entire game from a fresh player perspective.

Verify:

1. Player spawns in town.
2. Player receives a Haunt.
3. Player can enter the Mansion.
4. Ghosts spawn.
5. Player can see them.
6. Player can use flashlight.
7. Player can target a ghost.
8. Vacuum starts sucking.
9. Player can spam click.
10. Ghost resists.
11. Ghost moves away.
12. Player can chase it.
13. Capture meter progresses.
14. Ghost gets sucked into the vacuum.
15. Ghost is added to collection.
16. Player can return to Haunt.
17. Player can place ghost.
18. Ghost generates $/sec.
19. Money increases.
20. Player can buy vacuum upgrades.
21. Player can upgrade Haunt.
22. Player can unlock deeper Mansion areas.
23. Better ghosts spawn in deeper areas.
24. Player can capture rarer ghosts.
25. Player can Rebirth.
26. Rebirth multiplier works.
27. Player collection persists.
28. Haunt Chamber works.
29. Ghosts hunt autonomously in Haunt Chamber.
30. Data saves after leaving.

Fix anything that does not work.

---

# STEP 37 — DO NOT STOP AT A PROTOTYPE

I do NOT want a response that says:

"Here is how you could build this."

I want you to **BUILD IT**.

Do not stop after writing the architecture.

Do not stop after creating one ghost.

Do not stop after creating the vacuum.

Continue implementing the systems until the project has a functional playable version of the game.

If polished custom assets are not available, create functional Roblox placeholder models using Parts/MeshParts/basic geometry and organize them so they can easily be replaced later.

The game must be playable even if some visual assets are placeholders.

---

# FINAL GAME IDENTITY

The final game should feel like:

**A spooky Roblox simulator where YOU personally enter a haunted mansion with a ghost-catching vacuum, explore dark rooms with a flashlight, find ghosts, chase them, fight their resistance, spam click to overpower them, and physically suck them into your vacuum.**

Then:

**You bring your captured ghosts back to your Haunt.**

**You place them inside your Haunt.**

**They generate $/sec.**

**You use that money to upgrade your vacuum, flashlight, movement, Haunt, and Mansion access.**

**You enter deeper and scarier areas.**

**You find stronger, rarer ghosts.**

**You eventually Rebirth and become permanently stronger.**

And when you want to be AFK:

**You enter the Haunt Chamber.**

**Your ghosts hunt for you inside a haunted mansion while you watch from a top-down view.**

The three major pillars are:

# 1. HUNT

**I personally hunt ghosts.**

# 2. HAUNT

**My captured ghosts generate $/sec.**

# 3. HAUNT CHAMBER

**My ghosts hunt autonomously while I watch / AFK.**

Everything in the project should support these three pillars.

Keep the game simple.

Keep it spooky.

Keep the progression satisfying.

Keep the hunting interactive.

And most importantly:

**BUILD THE GAME IN THE PROJECT — DO NOT JUST WRITE ABOUT IT.**