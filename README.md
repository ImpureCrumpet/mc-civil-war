# Civil War Mod

A lightweight Fabric mod for Minecraft 1.21.7+ that introduces natural hostilities between Undead and Illager factions, creating dynamic battlefield encounters throughout your world.

## What This Mod Does

### Core Functionality

**Civil War Mod** forces natural aggression between two major hostile factions in Minecraft:

- **Undead Faction**: Zombies and Skeletons
- **Illager Faction**: Pillagers, Vindicators, Evokers, and other Illagers

### Behavior Details

- **Natural Aggression**: Mobs from opposing factions will attack each other on sight without needing to be hit first
- **High Priority Targeting**: Enemy factions are treated with equal priority to Players (Priority 2), meaning mobs will actively seek out and engage enemy faction members
- **Proximity-Based Combat**: Mobs will attack whichever valid target (Player or Enemy Faction) is closest, creating dynamic three-way battles
- **Faction Coverage**:
  - **Zombies** target all Illager types (Pillagers, Vindicators, Evokers, etc.)
  - **Illagers** target Zombies and Skeletons

### Gameplay Impact

This mod transforms the Minecraft world into a more dynamic battlefield where:
- You might stumble upon epic battles between Zombies and Pillagers
- Villages become more dangerous as Illagers fight off Zombie hordes
- Strategic opportunities arise as factions weaken each other
- The world feels more alive with ongoing conflicts between hostile mobs

## Technical Details

- **Minecraft Version**: 1.21.0 - 1.21.11 (default: 1.21.7)
- **Mod Loader**: Fabric
- **Java Version**: 21+
- **Architecture**: Mixin-based injection into entity AI goal systems
- **Performance**: Lightweight with minimal overhead
- **Compatibility**: See [Version Matrix](ref/version-matrix.md) for validated versions

## Installation

1. Install [Fabric Loader](https://fabricmc.net/use/) 0.18.2+ for Minecraft 1.21.7+
2. Install [Fabric API](https://modrinth.com/mod/fabric-api) 0.129.0+
3. Place the `civil-war-1.0.0.jar` file in your `.minecraft/mods/` folder
4. Launch Minecraft

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

## Publishing to Modrinth

### Automated Publishing with API

The project includes scripts for automated publishing to Modrinth:

1. **Set up Personal Access Token (PAT):**
   - Get your PAT from [Modrinth Account Settings](https://modrinth.com/settings/account)
   - Copy `.env.example` to `.env`: `cp .env.example .env`
   - Add your token to `.env`: `MODRINTH_TOKEN=mrp_your_token_here`

2. **Publish a version:**
   ```bash
   ./scripts/publish-modrinth.sh <minecraft_version> <mod_version> [changelog_file]
   ```
   
   Example:
   ```bash
   ./scripts/publish-modrinth.sh 1.21.7 1.0.1 CHANGELOG.md
   ```

3. **API Documentation:**
   - [Modrinth API Documentation](https://docs.modrinth.com/api/)
   - See [MODRINTH_API.md](ref/MODRINTH_API.md) for detailed API integration guide

**Requirements:** `curl` and `jq` must be installed.

## API References

When developing or modifying this mod, refer to:

- [Fabric Loader 0.18.2 API](https://maven.fabricmc.net/docs/fabric-loader-0.18.2/)
- [Fabric API 0.129.0+1.21.7 API](https://maven.fabricmc.net/docs/fabric-api-0.129.0+1.21.7/)
- [Yarn 1.21.7+build.8 API](https://maven.fabricmc.net/docs/yarn-1.21.7+build.8/)

## License

This project is licensed under the same license as the template (see LICENSE file).

## Release Strategy

This mod follows a versioned release strategy for Minecraft 1.21.x:

- **Branch Strategy**: 
  - `main`: Development branch for all fixes and features
  - `1.21.x`: Version-specific branch for 1.21.x releases
- **Versioning**: Each Minecraft patch version gets its own mod release (e.g., `v1.0.1-mc1.21.7`)
- **Compatibility**: Validated against Minecraft 1.21.0 through 1.21.11
- **Publishing**: Releases are published to [Modrinth](https://modrinth.com/mod/civil-war)

For detailed release process, see [RELEASE_PROCESS.md](ref/RELEASE_PROCESS.md).  
For version compatibility matrix, see [version-matrix.md](ref/version-matrix.md).

## Contributing

Contributions are welcome! Please ensure your code follows the existing Mixin-based architecture and maintains compatibility with the target Minecraft version.

### Development Workflow

1. Make changes on `main` branch
2. Test thoroughly
3. For releases, cherry-pick fixes to `1.21.x` branch
4. Follow the release process in [RELEASE_PROCESS.md](ref/RELEASE_PROCESS.md)
