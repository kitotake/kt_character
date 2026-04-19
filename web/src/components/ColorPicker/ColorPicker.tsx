import styles from "./ColorPicker.module.sass";

// GTA V hair color palette (indices 0–63 approximated)
const HAIR_COLORS: string[] = [
  "#1a0a00", "#2c1300", "#3d1c00", "#4e2500", "#5c2e00",
  "#6b3800", "#7a4200", "#8a4e00", "#9a5a00", "#aa6600",
  "#ba7200", "#ca7e00", "#da8a00", "#e8960a", "#f0a020",
  "#f5b040", "#f8c060", "#fad080", "#fde0a0", "#fff0c0",
  "#c8a060", "#b89050", "#a88040", "#987030", "#886020",
  "#785010", "#684008", "#583205", "#3c1e02", "#200800",
  "#c0c0c0", "#a8a8a8", "#909090", "#787878", "#606060",
  "#484848", "#303030", "#181818", "#080808", "#000000",
  "#ff4040", "#e03030", "#c02020", "#a01010", "#800000",
  "#ff8040", "#e06020", "#c04010", "#a02808", "#801800",
  "#40a040", "#208020", "#106010", "#004000", "#002800",
  "#4080ff", "#2060e0", "#1040c0", "#0820a0", "#000080",
  "#c040ff", "#a020e0", "#8010c0", "#6008a0", "#400080",
];

interface ColorPickerProps {
  label: string;
  value: number;
  onChange: (value: number) => void;
}

export default function ColorPicker({ label, value, onChange }: ColorPickerProps) {
  const currentColor = HAIR_COLORS[value] ?? "#1a0a00";

  return (
    <div className={styles.wrapper}>
      <div className={styles.header}>
        <span className={styles.label}>{label}</span>
        <div
          className={styles.preview}
          style={{ backgroundColor: currentColor }}
          title={`Couleur ${value}`}
        />
      </div>

      <div className={styles.grid}>
        {HAIR_COLORS.map((color, i) => (
          <button
            key={i}
            className={`${styles.swatch} ${value === i ? styles.selected : ""}`}
            style={{ backgroundColor: color }}
            title={`Couleur ${i}`}
            onClick={() => onChange(i)}
          />
        ))}
      </div>

      <span className={styles.indexLabel}>Index: {value}</span>
    </div>
  );
}