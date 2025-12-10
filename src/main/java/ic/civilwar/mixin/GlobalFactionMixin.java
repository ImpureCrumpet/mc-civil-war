package ic.civilwar.mixin;

import ic.civilwar.CivilWar;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.ai.goal.ActiveTargetGoal;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.registry.tag.EntityTypeTags;
import net.minecraft.registry.tag.TagKey;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Universal faction logic injected into all MobEntity mobs.
 * Applies only to hostile entities and uses EntityTypeTags checks to stay future-proof.
 * 
 * This mixin adds faction-based targeting goals:
 * - Undead mobs (tagged with SENSITIVE_TO_SMITE) will target Illagers (RAIDERS and ILLAGER tags) and Arthropods (spiders/cave spiders)
 * - Illagers (RAIDERS and ILLAGER tags) will target Undead mobs and Arthropods (spiders/cave spiders)
 * - Arthropods (spiders/cave spiders, excluding silverfish/bees/endermites) will target Undead and Illagers
 * All use priority 2, matching player targeting priority.
 */
@Mixin(MobEntity.class)
public abstract class GlobalFactionMixin {

    @Shadow
    protected net.minecraft.entity.ai.goal.GoalSelector targetSelector;

    /**
     * Priority for faction targeting goals. Matches player targeting priority (2)
     * to ensure mobs treat enemy factions with equal importance to players.
     */
    private static final int FACTION_TARGET_PRIORITY = 2;

    /**
     * Injects faction-based targeting goals into hostile mobs during goal initialization.
     * 
     * @param ci Callback info for the injection point
     */
    @Inject(method = "initGoals", at = @At("TAIL"))
    private void addCivilWarGoals(CallbackInfo ci) {
        try {
            // Skip non-hostile mobs that also inherit MobEntity (e.g., villagers).
            if (!((Object) this instanceof HostileEntity)) {
                return;
            }

            HostileEntity self = (HostileEntity) (Object) this;
            
            // Safety check: ensure entity type is valid
            if (self.getType() == null) {
                return;
            }

            boolean isUndead = self.getType().isIn(EntityTypeTags.SENSITIVE_TO_SMITE);
            // Check for both RAIDERS and ILLAGER tags to ensure all illager types are covered, including Raiders
            boolean isIllager = self.getType().isIn(EntityTypeTags.RAIDERS) 
                || self.getType().isIn(EntityTypeTags.ILLAGER);
            // Check for ARTHROPOD tag but exclude problematic mobs (silverfish, bees, endermites)
            // Net result: only spiders and cave spiders participate
            boolean isArthropod = self.getType().isIn(EntityTypeTags.ARTHROPOD)
                && self.getType() != EntityType.SILVERFISH
                && self.getType() != EntityType.BEE
                && self.getType() != EntityType.ENDERMITE;

            // Undead target Illagers and Arthropods at priority 2 (same as players).
            // Target both RAIDERS and ILLAGER tags to ensure comprehensive coverage, including Raiders
            if (isUndead) {
                addFactionTarget(self, EntityTypeTags.RAIDERS);
                addFactionTarget(self, EntityTypeTags.ILLAGER);
                addFactionTargetWithExclusions(self, EntityTypeTags.ARTHROPOD);
            }

            // Illagers target Undead and Arthropods at priority 2 (same as players).
            if (isIllager) {
                addFactionTarget(self, EntityTypeTags.SENSITIVE_TO_SMITE);
                addFactionTargetWithExclusions(self, EntityTypeTags.ARTHROPOD);
            }

            // Arthropods (spiders/cave spiders) target Undead and Illagers at priority 2 (same as players).
            if (isArthropod) {
                addFactionTarget(self, EntityTypeTags.SENSITIVE_TO_SMITE);
                addFactionTarget(self, EntityTypeTags.RAIDERS);
                addFactionTarget(self, EntityTypeTags.ILLAGER);
            }
        } catch (Exception e) {
            CivilWar.LOGGER.error("Failed to add civil war goals for entity {}", this, e);
        }
    }

    /**
     * Helper method to add a faction targeting goal to the entity's target selector.
     * 
     * @param entity The hostile entity to add the goal to
     * @param targetTag The entity type tag to target
     */
    private void addFactionTarget(HostileEntity entity, TagKey<net.minecraft.entity.EntityType<?>> targetTag) {
        // Access targetSelector through shadow field
        this.targetSelector.add(FACTION_TARGET_PRIORITY, new ActiveTargetGoal<LivingEntity>(
            entity,
            LivingEntity.class,
            true,
            (target, world) -> target.getType() != null && target.getType().isIn(targetTag)
        ));
    }

    /**
     * Helper method to add a faction targeting goal with exclusions for problematic arthropods.
     * Excludes silverfish (swarm behavior), bees (neutral), and endermites (special mechanics).
     * 
     * @param entity The hostile entity to add the goal to
     * @param targetTag The entity type tag to target (should be ARTHROPOD)
     */
    private void addFactionTargetWithExclusions(HostileEntity entity, TagKey<net.minecraft.entity.EntityType<?>> targetTag) {
        // Access targetSelector through shadow field
        this.targetSelector.add(FACTION_TARGET_PRIORITY, new ActiveTargetGoal<LivingEntity>(
            entity,
            LivingEntity.class,
            true,
            (target, world) -> {
                if (target.getType() == null) {
                    return false;
                }
                // Must be in the tag AND not be one of the excluded types
                return target.getType().isIn(targetTag)
                    && target.getType() != EntityType.SILVERFISH
                    && target.getType() != EntityType.BEE
                    && target.getType() != EntityType.ENDERMITE;
            }
        ));
    }
}
