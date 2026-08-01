import styles from "./Parents.module.scss";
import Slider from "../Slider/Slider";
import type { HeadBlend } from "../../types/appearance.types";

// Noms GTA V (indices 0-45 des têtes MP)
const PARENT_NAMES: string[] = [
  "Benjamin", "Daniel", "Joshua", "Noah", "Andrew", "Juan", "Alex",
  "Isaac", "Evan", "Ethan", "Vincent", "Angel", "Diego", "Adrian",
  "Gabriel", "Michael", "Santiago", "Kevin", "Louis", "Samuel",
  "Anthony", "David", "Nathan", "Christian", "Jonathan", "Tyler",
  "Ryan", "Nicholas", "Eric", "Justin", "Brian", "Richard", "Timothy",
  "Devin", "Jordan", "Fernando", "Peter", "Eduardo", "Elias", "Johnny",
  "Malcolm", "Alfredo", "Brad", "Simon", "Niko", "Claude",
];

interface ParentsProps {
  data: HeadBlend;
  onChange: (data: HeadBlend) => void;
}

export default function Parents({ data, onChange }: ParentsProps) {
  const update = (key: keyof HeadBlend, value: number) =>
    onChange({ ...data, [key]: value });

  // Sliders internes en 0-100, stocké en 0.0-1.0
  const shapePct = Math.round(data.shapeMix * 100);
  const skinPct  = Math.round(data.skinMix  * 100);

  const fatherName = PARENT_NAMES[data.shapeFirst]  ?? `#${data.shapeFirst}`;
  const motherName = PARENT_NAMES[data.shapeSecond] ?? `#${data.shapeSecond}`;

  return (
    <div className={styles.wrapper}>

      {/* Barre de mélange visuelle */}
      <div className={styles.blendBar}>
        <span className={styles.blendLabel}>{fatherName}</span>
        <div className={styles.barTrack}>
          <div
            className={styles.barFill}
            style={{ width: `${100 - shapePct}%` }}
          />
        </div>
        <span className={styles.blendLabel}>{motherName}</span>
      </div>

      {/* Sélecteurs parents */}
      <div className={styles.row}>
        <Slider
          label="Père"
          min={0} max={45}
          value={data.shapeFirst}
          onChange={(v) => update("shapeFirst", v)}
        />
        <Slider
          label="Mère"
          min={0} max={45}
          value={data.shapeSecond}
          onChange={(v) => update("shapeSecond", v)}
        />
      </div>

      {/* Mix forme */}
      <Slider
        label={`Forme — ${100 - shapePct}% père · ${shapePct}% mère`}
        min={0} max={100} step={1}
        value={shapePct}
        onChange={(v) => update("shapeMix", v / 100)}
      />

      <div className={styles.divider} />

      {/* Sélecteurs teint */}
      <div className={styles.row}>
        <Slider
          label="Teint père"
          min={0} max={45}
          value={data.skinFirst}
          onChange={(v) => update("skinFirst", v)}
        />
        <Slider
          label="Teint mère"
          min={0} max={45}
          value={data.skinSecond}
          onChange={(v) => update("skinSecond", v)}
        />
      </div>

      {/* Mix teint */}
      <Slider
        label={`Teint — ${100 - skinPct}% père · ${skinPct}% mère`}
        min={0} max={100} step={1}
        value={skinPct}
        onChange={(v) => update("skinMix", v / 100)}
      />
    </div>
  );
}
