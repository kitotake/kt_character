// web/src/components/ModelPicker/ModelPicker.tsx
// Sélecteur de modèle ped avec previews visuelles SVG

import { useState } from "react";
import styles from "./ModelPicker.module.scss";

interface ModelDef {
  model: string;
  label: string;
  gender: "male" | "female";
  skinTone: string;
  hairColor: string;
  clothesColor: string;
  accentColor: string;
}

// Modèles disponibles GTA V MP freemode + quelques variantes
const MODEL_DEFS: ModelDef[] = [
  // ── Males ──
  {
    model: "mp_m_freemode_01",
    label: "Male",
    gender: "male",
    skinTone: "#d4956e",
    hairColor: "#1a0a00",
    clothesColor: "#2a3060",
    accentColor: "#4a90d9",
  },
  {
    model: "mp_m_freemode_01_tan",
    label: "Male Tanné",
    gender: "male",
    skinTone: "#c07840",
    hairColor: "#2c1300",
    clothesColor: "#3a2010",
    accentColor: "#d97a20",
  },
  {
    model: "mp_m_freemode_01_dark",
    label: "Male Sombre",
    gender: "male",
    skinTone: "#6a3818",
    hairColor: "#0a0500",
    clothesColor: "#1a1a2a",
    accentColor: "#707084",
  },
  {
    model: "mp_m_freemode_01_pale",
    label: "Male Pâle",
    gender: "male",
    skinTone: "#f0c8a0",
    hairColor: "#f8c060",
    clothesColor: "#2a2a3a",
    accentColor: "#c040ff",
  },
  // ── Females ──
  {
    model: "mp_f_freemode_01",
    label: "Female",
    gender: "female",
    skinTone: "#e8b99a",
    hairColor: "#3d1c00",
    clothesColor: "#3a1a40",
    accentColor: "#ff69b4",
  },
  {
    model: "mp_f_freemode_01_tan",
    label: "Female Tannée",
    gender: "female",
    skinTone: "#cc8850",
    hairColor: "#4e2500",
    clothesColor: "#2a1010",
    accentColor: "#e06020",
  },
  {
    model: "mp_f_freemode_01_dark",
    label: "Female Sombre",
    gender: "female",
    skinTone: "#7a4828",
    hairColor: "#100800",
    clothesColor: "#1a1020",
    accentColor: "#a020e0",
  },
  {
    model: "mp_f_freemode_01_pale",
    label: "Female Pâle",
    gender: "female",
    skinTone: "#f8d8c0",
    hairColor: "#fff0c0",
    clothesColor: "#2a2040",
    accentColor: "#ff4080",
  },
];

// ─── Preview SVG d'un ped ────────────────────────────────────────────────
function PedPreviewSvg({
  def,
  selected,
}: {
  def: ModelDef;
  selected: boolean;
}) {
  const isFemale = def.gender === "female";
  const id = def.model.replace(/[^a-z0-9]/gi, "_");

  return (
    <svg viewBox="0 0 80 130" xmlns="http://www.w3.org/2000/svg" className={styles.preview}>
      <defs>
        <linearGradient id={`bg_${id}`} x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor={selected ? `${def.accentColor}22` : "#14141e"} />
          <stop offset="100%" stopColor="#0a0a12" />
        </linearGradient>
        <linearGradient id={`cloth_${id}`} x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={def.clothesColor} />
          <stop offset="100%" stopColor={`${def.clothesColor}88`} />
        </linearGradient>
        <filter id={`shadow_${id}`}>
          <feDropShadow dx="0" dy="2" stdDeviation="2" floodColor="#000" floodOpacity="0.5" />
        </filter>
      </defs>

      {/* Fond */}
      <rect width="80" height="130" fill={`url(#bg_${id})`} />

      {/* Reflet sélection */}
      {selected && (
        <rect width="80" height="130" fill={def.accentColor} opacity="0.04" />
      )}

      {/* Ombre sol */}
      <ellipse cx="40" cy="126" rx="18" ry="3.5" fill="#000" opacity="0.4" />

      {isFemale ? (
        <g filter={`url(#shadow_${id})`}>
          {/* Jambes */}
          <rect x="29" y="88" width="9" height="32" rx="3" fill={`url(#cloth_${id})`} />
          <rect x="42" y="88" width="9" height="32" rx="3" fill={`url(#cloth_${id})`} />
          <ellipse cx="33" cy="120" rx="6" ry="3" fill="#111" />
          <ellipse cx="46" cy="120" rx="6" ry="3" fill="#111" />

          {/* Torse */}
          <rect x="26" y="58" width="28" height="34" rx="5" fill={`url(#cloth_${id})`} />
          {/* Bras */}
          <rect x="14" y="60" width="10" height="26" rx="4" fill={`url(#cloth_${id})`} />
          <rect x="56" y="60" width="10" height="26" rx="4" fill={`url(#cloth_${id})`} />
          <ellipse cx="19" cy="87" rx="5" ry="4" fill={def.skinTone} />
          <ellipse cx="61" cy="87" rx="5" ry="4" fill={def.skinTone} />

          {/* Cou */}
          <rect x="36" y="47" width="8" height="13" rx="3" fill={def.skinTone} />

          {/* Tête */}
          <ellipse cx="40" cy="38" rx="15" ry="17" fill={def.skinTone} />
          {/* Cheveux */}
          <ellipse cx="40" cy="24" rx="16" ry="10" fill={def.hairColor} />
          <rect x="24" y="24" width="5" height="14" rx="2.5" fill={def.hairColor} />
          <rect x="51" y="24" width="5" height="14" rx="2.5" fill={def.hairColor} />
          {/* Yeux */}
          <ellipse cx="35" cy="38" rx="2" ry="2.2" fill="#1a1a0a" />
          <ellipse cx="45" cy="38" rx="2" ry="2.2" fill="#1a1a0a" />
          <ellipse cx="35.4" cy="37.3" rx="0.7" ry="0.7" fill="#fff" opacity="0.7" />
          <ellipse cx="45.4" cy="37.3" rx="0.7" ry="0.7" fill="#fff" opacity="0.7" />
          {/* Sourcils */}
          <path d="M32 33 Q35 31.5 38 33" stroke="#3d1c00" strokeWidth="0.8" fill="none" />
          <path d="M42 33 Q45 31.5 48 33" stroke="#3d1c00" strokeWidth="0.8" fill="none" />
          {/* Bouche */}
          <path d="M37 45 Q40 48 43 45" stroke="#c07060" strokeWidth="1" fill="none" strokeLinecap="round" />
          {/* Oreilles */}
          <ellipse cx="25" cy="40" rx="2" ry="3" fill={def.skinTone} />
          <ellipse cx="55" cy="40" rx="2" ry="3" fill={def.skinTone} />
        </g>
      ) : (
        <g filter={`url(#shadow_${id})`}>
          {/* Jambes */}
          <rect x="27" y="88" width="11" height="33" rx="3" fill={`url(#cloth_${id})`} />
          <rect x="42" y="88" width="11" height="33" rx="3" fill={`url(#cloth_${id})`} />
          <ellipse cx="32" cy="121" rx="7" ry="3" fill="#111" />
          <ellipse cx="47" cy="121" rx="7" ry="3" fill="#111" />

          {/* Torse large */}
          <rect x="23" y="55" width="34" height="36" rx="5" fill={`url(#cloth_${id})`} />
          {/* Bras */}
          <rect x="11" y="56" width="11" height="28" rx="4" fill={`url(#cloth_${id})`} />
          <rect x="58" y="56" width="11" height="28" rx="4" fill={`url(#cloth_${id})`} />
          <ellipse cx="16" cy="85" rx="6" ry="5" fill={def.skinTone} />
          <ellipse cx="64" cy="85" rx="6" ry="5" fill={def.skinTone} />

          {/* Cou */}
          <rect x="35" y="45" width="10" height="12" rx="3" fill={def.skinTone} />

          {/* Tête */}
          <ellipse cx="40" cy="36" rx="16" ry="18" fill={def.skinTone} />
          {/* Cheveux courts */}
          <ellipse cx="40" cy="21" rx="16" ry="9" fill={def.hairColor} />
          <rect x="24" y="21" width="4" height="8" rx="2" fill={def.hairColor} />
          <rect x="52" y="21" width="4" height="8" rx="2" fill={def.hairColor} />
          {/* Yeux */}
          <ellipse cx="34" cy="35" rx="2.5" ry="2.5" fill="#1a1a0a" />
          <ellipse cx="46" cy="35" rx="2.5" ry="2.5" fill="#1a1a0a" />
          <ellipse cx="34.5" cy="34.2" rx="0.8" ry="0.8" fill="#fff" opacity="0.7" />
          <ellipse cx="46.5" cy="34.2" rx="0.8" ry="0.8" fill="#fff" opacity="0.7" />
          {/* Sourcils épais */}
          <path d="M30 28 Q34 26.5 38 28" stroke="#1a0a00" strokeWidth="1.4" fill="none" />
          <path d="M42 28 Q46 26.5 50 28" stroke="#1a0a00" strokeWidth="1.4" fill="none" />
          {/* Bouche */}
          <path d="M36 46 Q40 49 44 46" stroke="#a06050" strokeWidth="0.9" fill="none" strokeLinecap="round" />
          {/* Oreilles */}
          <ellipse cx="24" cy="38" rx="2.5" ry="3.5" fill={def.skinTone} />
          <ellipse cx="56" cy="38" rx="2.5" ry="3.5" fill={def.skinTone} />
        </g>
      )}

      {/* Bordure sélection */}
      {selected && (
        <rect
          width="80"
          height="130"
          fill="none"
          stroke={def.accentColor}
          strokeWidth="2"
          opacity="0.8"
        />
      )}
    </svg>
  );
}

// ─── Props ────────────────────────────────────────────────────────────────
interface ModelPickerProps {
  value: string;
  onChange: (model: string) => void;
}

export default function ModelPicker({ value, onChange }: ModelPickerProps) {
  const [filter, setFilter] = useState<"all" | "male" | "female">("all");

  const filtered = MODEL_DEFS.filter(
    (m) => filter === "all" || m.gender === filter
  );

  const selected = MODEL_DEFS.find((m) => m.model === value);

  return (
    <div className={styles.wrapper}>
      {/* Filtre genre */}
      <div className={styles.filters}>
        {(["all", "male", "female"] as const).map((f) => (
          <button
            key={f}
            className={[styles.filterBtn, filter === f ? styles.filterActive : ""].join(" ")}
            onClick={() => setFilter(f)}
          >
            {f === "all" ? "Tous" : f === "male" ? "♂ Masculins" : "♀ Féminins"}
          </button>
        ))}
      </div>

      {/* Info modèle sélectionné */}
      {selected && (
        <div className={styles.selectedInfo}>
          <span className={styles.selectedDot} style={{ background: selected.accentColor }} />
          <span className={styles.selectedLabel}>{selected.label}</span>
          <span className={styles.selectedModel}>{selected.model}</span>
        </div>
      )}

      {/* Grille de modèles */}
      <div className={styles.grid}>
        {filtered.map((def) => (
          <button
            key={def.model}
            className={[
              styles.modelCard,
              value === def.model ? styles.modelSelected : "",
            ].join(" ")}
            onClick={() => onChange(def.model)}
            title={def.label}
          >
            <PedPreviewSvg def={def} selected={value === def.model} />
            <div className={styles.modelLabel}>{def.label}</div>
          </button>
        ))}
      </div>
    </div>
  );
}
