package ic.civilwar.mixin;

import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.ai.goal.ActiveTargetGoal;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.registry.tag.EntityTypeTags;
import net.minecraft.world.World;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Universal faction logic injected into all MobEntity mobs.
 * Applies only to hostile entities and uses EntityGroup checks to stay future-proof.
 */
@Mixin(MobEntity.class)
public abstract class GlobalFactionMixin extends MobEntity {

    protected GlobalFactionMixin(EntityType<? extends MobEntity> entityType, World world) {
        super(entityType, world);
    }

    @Inject(method = "initGoals", at = @At("TAIL"))
    private void addCivilWarGoals(CallbackInfo ci) {
        // Skip non-hostile mobs that also inherit PathAwareEntity (e.g., villagers).
        if (!((Object) this instanceof HostileEntity)) {
            return;
        }

        HostileEntity self = (HostileEntity) (Object) this;
        boolean isUndead = self.getType().isIn(EntityTypeTags.SENSITIVE_TO_SMITE);
        boolean isIllager = self.getType().isIn(EntityTypeTags.RAIDERS);

        // Undead target Illagers at priority 2 (same as players).
        if (isUndead) {
            this.targetSelector.add(2, new ActiveTargetGoal<LivingEntity>(
                self,
                LivingEntity.class,
                true,
                (target, world) -> target.getType().isIn(EntityTypeTags.RAIDERS)
            ));
        }

        // Illagers target Undead at priority 2 (same as players).
        if (isIllager) {
            this.targetSelector.add(2, new ActiveTargetGoal<LivingEntity>(
                self,
                LivingEntity.class,
                true,
                (target, world) -> target.getType().isIn(EntityTypeTags.SENSITIVE_TO_SMITE)
            ));
        }
    }
}
