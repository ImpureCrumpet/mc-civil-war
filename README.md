# Mob Civil War Mod

A lightweight Fabric mod for Minecraft 1.21.x that introduces natural hostilities between Undead, Illager, and Arthropod factions, creating dynamic battlefield encounters throughout your world.

## What This Mod Does

### Core Functionality

**Civil War Mod** forces natural aggression between three major hostile factions in Minecraft:

- **Undead Faction**: Zombies and Skeletons
- **Illager Faction**: Pillagers, Vindicators, Evokers, and other Illagers
- **Arthropod Faction**: Spiders and Cave Spiders

### Behavior Details

- **Natural Aggression**: Mobs from opposing factions will attack each other on sight without needing to be hit first
- **High Priority Targeting**: Enemy factions are treated with equal priority to Players (Priority 2), meaning mobs will actively seek out and engage enemy faction members
- **Proximity-Based Combat**: Mobs will attack whichever valid target (Player or Enemy Faction) is closest, creating dynamic three-way battles
- **Faction Coverage**:
  - **Undead** (Zombies, Skeletons) target Illagers and Spiders
  - **Illagers** (Pillagers, Vindicators, Evokers, etc.) target Undead and Spiders
  - **Spiders** (Spiders, Cave Spiders) target Undead and Illagers

### Gameplay Impact

This mod transforms the Minecraft world into a more dynamic battlefield where:
- You might stumble upon epic battles between Zombies, Pillagers, and Spiders
- Villages become more dangerous as Illagers fight off Zombie hordes while Spiders join the fray
- Strategic opportunities arise as factions weaken each other in three-way conflicts
- The world feels more alive with ongoing conflicts between hostile mobs

## Technical Details

- **Minecraft Version**: 1.21.x
- **Mod Loader**: Fabric
- **Java Version**: 21+
- **Architecture**: Mixin-based injection into entity AI goal systems
- **Performance**: Lightweight with minimal overhead

## Compatibility

This mod only adds faction-based targeting goals to hostile mobs' AI during initialization and should be compatible with most mods. It uses standard mixin injection points and doesn't modify or remove existing game behavior, making it safe to use alongside content mods, performance mods, and most other Fabric mods.

Potential conflicts may occur with mods that completely replace mob AI systems or heavily modify entity targeting behavior, though such mods are uncommon in the Fabric ecosystem.

## Installation

1. Install [Fabric Loader](https://fabricmc.net/use/) 0.18.2+ for Minecraft 1.21.7+
2. Install [Fabric API](https://modrinth.com/mod/fabric-api) 0.129.0+
3. Place the `civil-war-1.0.0.jar` file in your `.minecraft/mods/` folder (single-player) or server `mods/` folder (multiplayer)
4. Launch Minecraft

**Note**: For multiplayer servers, install the mod on the server. Clients don't need the mod installed, but it's safe to have it on both client and server.

## Building from Source

### Prerequisites

- Java Development Kit (JDK) 21 or higher
- Gradle (included via wrapper)

### Build Steps

1. Clone this repository
2. Navigate to the project directory
3. Run the build command:
   ```bash
   ./gradlew build
   ```
4. Find the compiled mod in `build/libs/`

### Version Updates

To update for a newer Minecraft version (e.g., 1.21.11):

**Option 1: Using helper script (recommended)**
```bash
./scripts/update-version.sh 1.21.11 1.0.1
# Then manually edit gradle.properties to update yarn_mappings and fabric_version
./scripts/validate-version.sh 1.21.11
./scripts/build-version.sh 1.21.11 1.0.1
```

**Option 2: Manual update**
1. Open `gradle.properties` in the project root
2. Update the following values:
   - `minecraft_version=1.21.11`
   - `yarn_mappings=1.21.11+build.X` (check [Fabric Development](https://fabricmc.net/develop) for exact version)
   - `loader_version=X.X.X` (check [Fabric Development](https://fabricmc.net/develop) for compatible version)
   - `fabric_version=X.X.X+1.21.11` (check [Fabric Development](https://fabricmc.net/develop) for exact version)
   - `mod_version=1.0.1` (increment for new release)
3. Run `./scripts/validate-version.sh 1.21.11` to validate compatibility
4. Run `./gradlew build` to build

See [Release Process](ref/RELEASE_PROCESS.md) for detailed release workflow.
