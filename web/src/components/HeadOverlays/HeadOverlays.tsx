import styles from "./HeadOverlays.module.scss";
import { useState } from "react";
import Slider from "../Slider/Slider";
import { OVERLAY_DEFS } from "../../types/appearance.types";
import type { HeadOverlays as HeadOverlaysType, HeadOverlay } from "../../types/appearance.types";

// Palette cheveux GTA V (0-63)
const HAIR_COLORS: string[] = [
  "#1a0a00","#2c1300","#3d1c00","#4e2500","#5c2e00","#6b3800","#7a4200","#8a4e00","#9a5a00","#aa6600",
  "#ba7200","#ca7e00","#da8a00","#e8960a","#f0a020","#f5b040","#f8c060","#fad080","#fde0a0","#fff0c0",
  "#c8a060","#b89050","#a88040","#987030","#886020","#785010","#684008","#583205","#3c1e02","#200800",
  "#c0c0c0","#a8a8a8","#909090","#787878","#606060","#484848","#303030","#181818","#080808","#000000",
  "#ff4040","#e03030","#c02020","#a01010","#800000","#ff8040","#e06020","#c04010","#a02808","#801800",
  "#40a040","#208020","#106010","#004000","#002800","#4080ff","#2060e0","#1040c0","#0820a0","#000080",
  "#c040ff","#a020e0","#8010c0","#6008a0",
];

// Palette maquillage GTA V (subset représentatif 0-63)
const MAKEUP_COLORS: string[] = [
  "#000000","#1a1a1a","#333333","#4d4d4d","#666666","#808080","#999999","#b3b3b3","#cccccc","#e6e6e6",
  "#8b0000","#a00000","#b22222","#cc0000","#dc143c","#e63946","#ff0000","#ff4444","#ff6666","#ff8888",
  "#800080","#8b008b","#9400d3","#a020f0","#b044f0","#c060ff","#d080ff","#e0a0ff","#4b0082","#6a0dad",
  "#ff69b4","#ff1493","#db7093","#c71585","#ff007f","#e75480","#de5285","#c2528a","#ad5d75","#994f6c",
  "#8b4513","#a0522d","#cd853f","#d2691e","#c0965a","#daa520","#b8860b","#ffd700","#ffa500","#ff8c00",
  "#006400","#228b22","#32cd32","#00ff00","#7cfc00","#adff2f","#00ced1","#40e0d0","#48d1cc","#00bcd4",
  "#ffffff","#f5f5f5","#dcdcdc","#d3d3d3",
];

interface HeadOverlaysProps {
  data: HeadOverlaysType;
  onChange: (data: HeadOverlaysType) => void;
}

export default function HeadOverlays({ data, onChange }: HeadOverlaysProps) {
  const [openId, setOpenId] = useState<number | null>(1); // barbe ouverte par défaut

  const updateOverlay = (id: number, patch: Partial<HeadOverlay>) => {
    onChange({
      ...data,
      [id]: { ...data[id], ...patch },
    });
  };

  const palette = (colorType: 0 | 1 | 2) =>
    colorType === 2 ? MAKEUP_COLORS : HAIR_COLORS;

  return (
    <div className={styles.wrapper}>
      {OVERLAY_DEFS.map((def) => {
        const overlay = data[def.id] ?? { index: 0, opacity: 1.0, firstColor: 0, secondColor: 0 };
        const isOpen   = openId === def.id;
        const isActive = overlay.index > 0;

        return (
          <div
            key={def.id}
            className={`${styles.card} ${isActive ? styles.active : ""}`}
          >
            {/* Header cliquable */}
            <div
              className={styles.cardHeader}
              onClick={() => setOpenId(isOpen ? null : def.id)}
            >
              <div className={styles.cardTitle}>
                <span className={styles.cardName}>{def.name}</span>
                {isActive && (
                  <span className={styles.cardBadge}>#{overlay.index}</span>
                )}
              </div>
              <span className={`${styles.chevron} ${isOpen ? styles.open : ""}`}>
                ▼
              </span>
            </div>

            {/* Corps (accordéon) */}
            {isOpen && (
              <div className={styles.cardBody}>
                {/* Index (variation) */}
                <Slider
                  label="Variation"
                  min={0}
                  max={def.maxIndex}
                  value={overlay.index}
                  onChange={(v) => updateOverlay(def.id, { index: v })}
                />

                {/* Opacité */}
                <Slider
                  label={`Opacité — ${Math.round(overlay.opacity * 100)}%`}
                  min={0}
                  max={100}
                  step={1}
                  value={Math.round(overlay.opacity * 100)}
                  onChange={(v) => updateOverlay(def.id, { opacity: v / 100 })}
                />

                {/* Couleur principale */}
                {def.hasColor && (
                  <div className={styles.colorRow}>
                    <span className={styles.colorLabel}>Couleur</span>
                    <div
                      className={styles.colorDot}
                      style={{ backgroundColor: palette(def.colorType)[overlay.firstColor] ?? "#000" }}
                    />
                    <div className={styles.colorSwatches}>
                      {palette(def.colorType).map((color, i) => (
                        <button
                          key={i}
                          className={`${styles.swatch} ${overlay.firstColor === i ? styles.selected : ""}`}
                          style={{ backgroundColor: color }}
                          title={`Couleur ${i}`}
                          onClick={() => updateOverlay(def.id, { firstColor: i })}
                        />
                      ))}
                    </div>
                  </div>
                )}

                {/* Couleur secondaire (highlight) — uniquement cheveux/poils */}
                {def.hasColor && def.colorType === 1 && (
                  <div className={styles.colorRow}>
                    <span className={styles.colorLabel}>Reflet</span>
                    <div
                      className={styles.colorDot}
                      style={{ backgroundColor: palette(def.colorType)[overlay.secondColor] ?? "#000" }}
                    />
                    <div className={styles.colorSwatches}>
                      {palette(def.colorType).map((color, i) => (
                        <button
                          key={i}
                          className={`${styles.swatch} ${overlay.secondColor === i ? styles.selected : ""}`}
                          style={{ backgroundColor: color }}
                          title={`Reflet ${i}`}
                          onClick={() => updateOverlay(def.id, { secondColor: i })}
                        />
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
