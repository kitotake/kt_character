import styles from "./Preview.module.scss";

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

interface PreviewProps {
  data: {
    hair: number;
    beard: number;
    hairColor: number;
  };
}

export default function Preview({ data }: PreviewProps) {
  const hairColor = HAIR_COLORS[data.hairColor] ?? "#3d1c00";
  const hairHeight = data.hair > 30 ? "50px" : data.hair > 10 ? "38px" : "26px";

  return (
    <div className={styles.preview}>
      <div className={styles.grid} />

      <div className={styles.figure}>
        <div className={styles.head}>
          <div
            className={styles.hair}
            style={{ backgroundColor: hairColor, height: hairHeight }}
          />
        </div>
        <div className={styles.body}>
          <div className={styles.arms}>
            <div className={styles.arm} />
            <div className={styles.arm} />
          </div>
        </div>
        <div className={styles.legs}>
          <div className={styles.leg} />
          <div className={styles.leg} />
        </div>
      </div>

      <div className={styles.badge}>
        <div className={styles.badgeRow}>
          <span className={styles.badgeLabel}>Cheveux</span>
          <span className={styles.badgeValue}>{data.hair}</span>
        </div>
        <div className={styles.badgeRow}>
          <span className={styles.badgeLabel}>Barbe</span>
          <span className={styles.badgeValue}>{data.beard}</span>
        </div>
      </div>
    </div>
  );
}