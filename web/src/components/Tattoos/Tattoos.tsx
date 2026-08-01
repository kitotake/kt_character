import styles from "./Tattoos.module.scss";
import { useState } from "react";
import {
  TATTOO_ZONE_LABELS,
  TATTOO_ZONE_ICONS,
} from "../../types/appearance.types";
import type { Tattoo, TattooZone } from "../../types/appearance.types";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DONNÉES TATOUAGES GTA V
// Source complète : https://github.com/DurtyFree/gta-v-data-dumps
// Chaque entrée = { collection, overlay } passés à GetHashKey() côté Lua
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const TATTOO_DATA: Tattoo[] = [
  // ── HEAD ──────────────────────────────────────────────────────────────
  { id: "head_01", zone: "head", label: "Crâne Tribal",    collection: "mpbeach_overlays",  overlay: "FM_Bea_M_Tattoo_Head_000_M" },
  { id: "head_02", zone: "head", label: "Toile Araignée",  collection: "mphipster_overlays",overlay: "FM_Hip_M_Tattoo_Head_000_M" },
  { id: "head_03", zone: "head", label: "Flammes Crâne",   collection: "mplowrider_overlays",overlay: "FM_Lor_M_Tattoo_Head_000_M" },
  { id: "head_04", zone: "head", label: "Symboles",         collection: "mpbiker_overlays",  overlay: "FM_Bik_M_Tattoo_Head_000_M" },
  { id: "head_05", zone: "head", label: "Dragon Nuque",    collection: "mpgunrunning_overlays", overlay: "FM_Gun_M_Tattoo_Head_000_M" },

  // ── TORSO ─────────────────────────────────────────────────────────────
  { id: "torso_01", zone: "torso", label: "Ailes d'Ange",    collection: "mpbeach_overlays",     overlay: "FM_Bea_M_Tattoo_Torso_000_M" },
  { id: "torso_02", zone: "torso", label: "Croix Gothic",    collection: "mphipster_overlays",   overlay: "FM_Hip_M_Tattoo_Torso_000_M" },
  { id: "torso_03", zone: "torso", label: "Aigle Imperial",  collection: "mplowrider_overlays",  overlay: "FM_Lor_M_Tattoo_Torso_000_M" },
  { id: "torso_04", zone: "torso", label: "Tigre",           collection: "mpbiker_overlays",     overlay: "FM_Bik_M_Tattoo_Torso_000_M" },
  { id: "torso_05", zone: "torso", label: "Koi",             collection: "mpsmuggler_overlays",  overlay: "FM_Smu_M_Tattoo_Torso_000_M" },
  { id: "torso_06", zone: "torso", label: "Rose & Épines",   collection: "mpchristmas2_overlays",overlay: "FM_Xm2_M_Tattoo_Torso_000_M" },

  // ── LEFT ARM ──────────────────────────────────────────────────────────
  { id: "larm_01", zone: "left_arm", label: "Ancre Marine",    collection: "mpbeach_overlays",   overlay: "FM_Bea_M_Tattoo_LeftArm_000_M" },
  { id: "larm_02", zone: "left_arm", label: "Tête de Mort",    collection: "mphipster_overlays", overlay: "FM_Hip_M_Tattoo_LeftArm_000_M" },
  { id: "larm_03", zone: "left_arm", label: "Serpent",         collection: "mplowrider_overlays",overlay: "FM_Lor_M_Tattoo_LeftArm_000_M" },
  { id: "larm_04", zone: "left_arm", label: "Tribal Manches",  collection: "mpbiker_overlays",   overlay: "FM_Bik_M_Tattoo_LeftArm_000_M" },
  { id: "larm_05", zone: "left_arm", label: "Éclairs",         collection: "mpgunrunning_overlays",overlay: "FM_Gun_M_Tattoo_LeftArm_000_M" },

  // ── RIGHT ARM ─────────────────────────────────────────────────────────
  { id: "rarm_01", zone: "right_arm", label: "Oeil Qui Voit",  collection: "mpbeach_overlays",   overlay: "FM_Bea_M_Tattoo_RightArm_000_M" },
  { id: "rarm_02", zone: "right_arm", label: "Papillon",       collection: "mphipster_overlays", overlay: "FM_Hip_M_Tattoo_RightArm_000_M" },
  { id: "rarm_03", zone: "right_arm", label: "Aztèque",        collection: "mplowrider_overlays",overlay: "FM_Lor_M_Tattoo_RightArm_000_M" },
  { id: "rarm_04", zone: "right_arm", label: "Flammes",        collection: "mpbiker_overlays",   overlay: "FM_Bik_M_Tattoo_RightArm_000_M" },
  { id: "rarm_05", zone: "right_arm", label: "Cyberpunk",      collection: "mpbattle_overlays",  overlay: "FM_Bat_M_Tattoo_RightArm_000_M" },

  // ── LEFT LEG ──────────────────────────────────────────────────────────
  { id: "lleg_01", zone: "left_leg", label: "Tribal Jambe",   collection: "mpbeach_overlays",   overlay: "FM_Bea_M_Tattoo_LeftLeg_000_M" },
  { id: "lleg_02", zone: "left_leg", label: "Étoile Nautique",collection: "mphipster_overlays", overlay: "FM_Hip_M_Tattoo_LeftLeg_000_M" },
  { id: "lleg_03", zone: "left_leg", label: "Dragon Jambe",   collection: "mplowrider_overlays",overlay: "FM_Lor_M_Tattoo_LeftLeg_000_M" },

  // ── RIGHT LEG ─────────────────────────────────────────────────────────
  { id: "rleg_01", zone: "right_leg", label: "Vague",          collection: "mpbeach_overlays",   overlay: "FM_Bea_M_Tattoo_RightLeg_000_M" },
  { id: "rleg_02", zone: "right_leg", label: "Dagger",         collection: "mphipster_overlays", overlay: "FM_Hip_M_Tattoo_RightLeg_000_M" },
  { id: "rleg_03", zone: "right_leg", label: "Serpent Enroulé",collection: "mplowrider_overlays",overlay: "FM_Lor_M_Tattoo_RightLeg_000_M" },
];

const ZONES: TattooZone[] = [
  "head", "torso", "left_arm", "right_arm", "left_leg", "right_leg",
];

interface TattoosProps {
  applied: Tattoo[];
  onChange: (tattoos: Tattoo[]) => void;
}

export default function Tattoos({ applied, onChange }: TattoosProps) {
  const [activeZone, setActiveZone] = useState<TattooZone>("torso");

  const isApplied = (tattoo: Tattoo) =>
    applied.some((t) => t.id === tattoo.id);

  const toggle = (tattoo: Tattoo) => {
    if (isApplied(tattoo)) {
      onChange(applied.filter((t) => t.id !== tattoo.id));
    } else {
      onChange([...applied, tattoo]);
    }
  };

  const clearZone = () => {
    onChange(applied.filter((t) => t.zone !== activeZone));
  };

  const zoneData = TATTOO_DATA.filter((t) => t.zone === activeZone);
  const zoneCount = (zone: TattooZone) =>
    applied.filter((t) => t.zone === zone).length;

  return (
    <div className={styles.wrapper}>

      {/* ─── Sélecteur de zone ─────────────────────────────────────────── */}
      <div className={styles.zones}>
        {ZONES.map((zone) => (
          <button
            key={zone}
            className={`${styles.zoneBtn} ${activeZone === zone ? styles.active : ""}`}
            onClick={() => setActiveZone(zone)}
          >
            <span className={styles.zoneIcon}>{TATTOO_ZONE_ICONS[zone]}</span>
            <span className={styles.zoneName}>{TATTOO_ZONE_LABELS[zone]}</span>
            {zoneCount(zone) > 0 && (
              <span className={styles.zoneCount}>{zoneCount(zone)}</span>
            )}
          </button>
        ))}
      </div>

      {/* ─── Grille de la zone sélectionnée ────────────────────────────── */}
      <div className={styles.gridHeader}>
        <span className={styles.gridTitle}>
          {TATTOO_ZONE_LABELS[activeZone]} ({zoneData.length})
        </span>
        {zoneCount(activeZone) > 0 && (
          <button className={styles.clearBtn} onClick={clearZone}>
            ✕ Effacer zone
          </button>
        )}
      </div>

      <div className={styles.grid}>
        {zoneData.length === 0 ? (
          <div className={styles.empty} style={{ gridColumn: "1 / -1" }}>
            Aucun tatouage disponible pour cette zone
          </div>
        ) : (
          zoneData.map((tattoo) => (
            <button
              key={tattoo.id}
              className={`${styles.tattooCard} ${isApplied(tattoo) ? styles.applied : ""}`}
              onClick={() => toggle(tattoo)}
              title={`${tattoo.collection} / ${tattoo.overlay}`}
            >
              <span className={styles.tattooLabel}>{tattoo.label}</span>
              <span className={styles.tattooCollection}>{tattoo.collection.replace("_overlays", "")}</span>
            </button>
          ))
        )}
      </div>

      {/* ─── Liste des tatouages appliqués ─────────────────────────────── */}
      {applied.length > 0 && (
        <div className={styles.appliedSection}>
          <span className={styles.appliedTitle}>
            Appliqués ({applied.length})
          </span>
          <div className={styles.appliedList}>
            {applied.map((tattoo) => (
              <div key={tattoo.id} className={styles.appliedItem}>
                <span className={styles.appliedLabel}>
                  {TATTOO_ZONE_ICONS[tattoo.zone]} {tattoo.label}
                </span>
                <button
                  className={styles.removeBtn}
                  onClick={() => toggle(tattoo)}
                >
                  ✕
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
