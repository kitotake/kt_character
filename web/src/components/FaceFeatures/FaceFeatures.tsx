import styles from "./FaceFeatures.module.scss";
import Slider from "../Slider/Slider";
import { FACE_FEATURE_LABELS } from "../../types/appearance.types";
import type { FaceFeatures as FaceFeaturesType } from "../../types/appearance.types";

interface FaceFeaturesProps {
  data: FaceFeaturesType; // tableau de 20 valeurs -1.0 → 1.0
  onChange: (data: FaceFeaturesType) => void;
}

export default function FaceFeatures({ data, onChange }: FaceFeaturesProps) {
  // Stocké en -1.0→1.0, slider en -100→100
  const updateFeature = (index: number, pct: number) => {
    const next = [...data];
    next[index] = parseFloat((pct / 100).toFixed(2));
    onChange(next);
  };

  const reset = () => onChange(new Array(20).fill(0.0));

  return (
    <div className={styles.wrapper}>
      <div className={styles.grid}>
        {Array.from({ length: 20 }, (_, i) => (
          <Slider
            key={i}
            label={FACE_FEATURE_LABELS[i] ?? `Feature ${i}`}
            min={-100}
            max={100}
            step={1}
            value={Math.round((data[i] ?? 0) * 100)}
            onChange={(v) => updateFeature(i, v)}
          />
        ))}
      </div>

      <div className={styles.resetRow}>
        <button className={styles.resetBtn} onClick={reset}>
          ↺ Réinitialiser
        </button>
      </div>
    </div>
  );
}
