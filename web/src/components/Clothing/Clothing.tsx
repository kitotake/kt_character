import styles from "./Clothing.module.scss";
import { useState } from "react";
import Slider from "../Slider/Slider";
import {
  COMPONENT_DEFS,
  PROP_DEFS,
} from "../../types/appearance.types";
import type {
  ClothingComponents,
  Props,
  ClothingComponent,
  Prop,
} from "../../types/appearance.types";

// Max hardcodés — idéalement dynamiques via GetNumberOfPedDrawableVariations
// Ces valeurs couvrent la grande majorité des vêtements MP
const COMPONENT_MAX_DRAWABLE = 128;
const COMPONENT_MAX_TEXTURE  = 16;
const PROP_MAX_INDEX         = 64;
const PROP_MAX_TEXTURE       = 16;

interface ClothingProps {
  components: ClothingComponents;
  props:      Props;
  onChangeComponents: (data: ClothingComponents) => void;
  onChangeProps:      (data: Props) => void;
}

export default function Clothing({
  components,
  props,
  onChangeComponents,
  onChangeProps,
}: ClothingProps) {
  const [openComp, setOpenComp] = useState<number | null>(null);
  const [openProp, setOpenProp] = useState<number | null>(null);

  // ── Components ──────────────────────────────────────────────────────────
  const updateComponent = (id: number, patch: Partial<ClothingComponent>) => {
    onChangeComponents({
      ...components,
      [id]: { ...components[id], ...patch },
    });
  };

  // ── Props ────────────────────────────────────────────────────────────────
  const updateProp = (anchor: number, patch: Partial<Prop>) => {
    onChangeProps({
      ...props,
      [anchor]: { ...props[anchor], ...patch },
    });
  };

  const removeProp = (anchor: number) => {
    onChangeProps({
      ...props,
      [anchor]: { propIndex: -1, propTextureIndex: 0 },
    });
  };

  return (
    <div className={styles.wrapper}>

      {/* ─── COMPOSANTS VÊTEMENTS ──────────────────────────────────────── */}
      <span className={styles.sectionTitle}>Vêtements</span>

      {COMPONENT_DEFS.map((def) => {
        const comp   = components[def.id] ?? { drawable: 0, texture: 0, palette: 0 };
        const isOpen = openComp === def.id;

        return (
          <div key={def.id} className={styles.card}>
            <div
              className={styles.cardHeader}
              onClick={() => setOpenComp(isOpen ? null : def.id)}
            >
              <div className={styles.cardLeft}>
                <span className={styles.icon}>{def.icon}</span>
                <span className={styles.cardName}>{def.name}</span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span className={styles.cardValues}>
                  {comp.drawable} / {comp.texture}
                </span>
                <span className={`${styles.chevron} ${isOpen ? styles.open : ""}`}>▼</span>
              </div>
            </div>

            {isOpen && (
              <div className={styles.cardBody}>
                <div className={styles.sliderRow}>
                  <Slider
                    label="Modèle"
                    min={0}
                    max={COMPONENT_MAX_DRAWABLE}
                    value={comp.drawable}
                    onChange={(v) => updateComponent(def.id, { drawable: v })}
                  />
                  <Slider
                    label="Texture"
                    min={0}
                    max={COMPONENT_MAX_TEXTURE}
                    value={comp.texture}
                    onChange={(v) => updateComponent(def.id, { texture: v })}
                  />
                </div>
              </div>
            )}
          </div>
        );
      })}

      {/* ─── PROPS (accessoires) ─────────────────────────────────────────── */}
      <span className={styles.sectionTitle} style={{ marginTop: 8 }}>
        Accessoires / Props
      </span>

      {PROP_DEFS.map((def) => {
        const prop   = props[def.anchor] ?? { propIndex: -1, propTextureIndex: 0 };
        const isOpen = openProp === def.anchor;
        const hasItem = prop.propIndex >= 0;

        return (
          <div key={def.anchor} className={styles.card}>
            <div
              className={styles.cardHeader}
              onClick={() => setOpenProp(isOpen ? null : def.anchor)}
            >
              <div className={styles.cardLeft}>
                <span className={styles.icon}>{def.icon}</span>
                <span className={styles.cardName}>{def.name}</span>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span className={styles.cardValues}>
                  {hasItem ? `${prop.propIndex} / ${prop.propTextureIndex}` : "Aucun"}
                </span>
                <span className={`${styles.chevron} ${isOpen ? styles.open : ""}`}>▼</span>
              </div>
            </div>

            {isOpen && (
              <div className={styles.cardBody}>
                <div className={styles.sliderRow}>
                  <Slider
                    label="Modèle"
                    min={0}
                    max={PROP_MAX_INDEX}
                    value={Math.max(0, prop.propIndex)}
                    onChange={(v) => updateProp(def.anchor, { propIndex: v })}
                  />
                  <Slider
                    label="Texture"
                    min={0}
                    max={PROP_MAX_TEXTURE}
                    value={prop.propTextureIndex}
                    onChange={(v) => updateProp(def.anchor, { propTextureIndex: v })}
                  />
                </div>
                {hasItem && (
                  <button
                    className={styles.removeBtn}
                    onClick={() => removeProp(def.anchor)}
                  >
                    ✕ Retirer
                  </button>
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
