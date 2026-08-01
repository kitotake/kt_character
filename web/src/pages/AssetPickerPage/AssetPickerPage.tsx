// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ASSET PICKER PAGE — v2
// Layout : [mini-preview SVG | AssetPicker]
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useCallback, useMemo } from "react";
import styles from "./AssetPickerPage.module.scss";
import { AssetPicker } from "../../components/AssetPicker";
import type { AssetPayload, GenderModel, PickerSelection } from "../../components/AssetPicker";
import type { ClothingComponents, Props, HeadOverlays } from "../../types/appearance.types";

// ── Conversions payload → types kt_character ──────────────────────────────
function payloadToComponents(payload: AssetPayload): ClothingComponents {
  const result: ClothingComponents = {};
  for (const [key, val] of Object.entries(payload.components)) {
    result[Number(key)] = { drawable: val.drawable, texture: val.texture, palette: val.palette };
  }
  return result;
}

function payloadToProps(payload: AssetPayload): Props {
  const result: Props = {};
  for (const [key, val] of Object.entries(payload.props)) {
    result[Number(key)] = { propIndex: val.propIndex, propTextureIndex: val.propTextureIndex };
  }
  return result;
}

function payloadToOverlays(payload: AssetPayload): HeadOverlays {
  const result: HeadOverlays = {};
  for (const [key, val] of Object.entries(payload.overlays)) {
    result[Number(key)] = {
      index: val.index,
      opacity: val.opacity,
      firstColor: val.firstColor,
      secondColor: val.secondColor,
    };
  }
  return result;
}

// ── Mini preview SVG ──────────────────────────────────────────────────────
// Palette cheveux GTA V (64 couleurs) — subset utilisé pour la preview
const HAIR_COLORS_PREVIEW: string[] = [
  "#1a0a00","#2c1300","#3d1c00","#4e2500","#5c2e00","#6b3800","#7a4200","#8a4e00","#9a5a00","#aa6600",
  "#ba7200","#ca7e00","#da8a00","#e8960a","#f0a020","#f5b040","#f8c060","#fad080","#fde0a0","#fff0c0",
  "#c8a060","#b89050","#a88040","#987030","#886020","#785010","#684008","#583205","#3c1e02","#200800",
  "#c0c0c0","#a8a8a8","#909090","#787878","#606060","#484848","#303030","#181818","#080808","#000000",
  "#ff4040","#e03030","#c02020","#a01010","#800000","#ff8040","#e06020","#c04010","#a02808","#801800",
  "#40a040","#208020","#106010","#004000","#002800","#4080ff","#2060e0","#1040c0","#0820a0","#000080",
  "#c040ff","#a020e0","#8010c0","#6008a0","#400080",
];

interface MiniPreviewProps {
  gender: GenderModel;
  selections: PickerSelection;
}

function MiniPreviewSvg({ gender, selections }: MiniPreviewProps) {
  const isFemale = gender === "mp_f_freemode_01";

  // Extraire les couleurs pertinentes
  const hairSel = selections["hair"];
  const hairColor = hairSel?.color !== undefined
    ? (HAIR_COLORS_PREVIEW[hairSel.color] ?? "#3d1c00")
    : "#3d1c00";
  const hairHighlight = hairSel?.highlight !== undefined
    ? (HAIR_COLORS_PREVIEW[hairSel.highlight] ?? hairColor)
    : hairColor;

  const facialSel = selections["facialHair"];
  const beardColor = facialSel?.color !== undefined
    ? (HAIR_COLORS_PREVIEW[facialSel.color] ?? "#2c1300")
    : "#2c1300";

  // // Couleur vêtements depuis jacket ou torso
  // const jacketSel = selections["jackets"] ?? selections["torsos"];
  // // texture jacket disponible via jacketSel?.texture

  // const pantsSel = selections["pants"];
  

  // const shoesSel = selections["shoes"];
  

  // Hair height basée sur le drawable
  const hairDrawable = hairSel?.drawable ?? 0;
  const hairLen = hairDrawable > 50 ? 22 : hairDrawable > 25 ? 16 : hairDrawable > 10 ? 11 : 7;

  // Barbe active ?
  const hasBeard = !isFemale && facialSel !== undefined && facialSel.drawable > 0;

  return (
    <svg viewBox="0 0 88 160" xmlns="http://www.w3.org/2000/svg" style={{ width: "100%", height: "auto", display: "block" }}>
      <defs>
        <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#14141e" />
          <stop offset="100%" stopColor="#0a0a12" />
        </linearGradient>
        <linearGradient id="hairGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={hairColor} />
          <stop offset="100%" stopColor={hairHighlight} />
        </linearGradient>
        <linearGradient id="bodyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#2a3060" />
          <stop offset="100%" stopColor="#1a1f3a" />
        </linearGradient>
        <radialGradient id="glowGrad" cx="50%" cy="30%" r="60%">
          <stop offset="0%" stopColor="rgba(0,217,255,0.08)" />
          <stop offset="100%" stopColor="rgba(0,217,255,0)" />
        </radialGradient>
        <filter id="softShadow">
          <feDropShadow dx="0" dy="2" stdDeviation="2" floodColor="#000" floodOpacity="0.5" />
        </filter>
      </defs>

      {/* Fond */}
      <rect width="88" height="160" fill="url(#bgGrad)" />
      <rect width="88" height="160" fill="url(#glowGrad)" />

      {/* Grille subtile */}
      <g opacity="0.04" stroke="#00d9ff" strokeWidth="0.5">
        {[0,22,44,66,88].map(x => <line key={x} x1={x} y1="0" x2={x} y2="160" />)}
        {[0,20,40,60,80,100,120,140,160].map(y => <line key={y} x1="0" y1={y} x2="88" y2={y} />)}
      </g>

      <g filter="url(#softShadow)">
        {/* ── Jambes ── */}
        <rect x={isFemale ? 30 : 28} y="110" width={isFemale ? 10 : 12} height="38" rx="3" fill="#1a1a2a" />
        <rect x={isFemale ? 48 : 48} y="110" width={isFemale ? 10 : 12} height="38" rx="3" fill="#1a1a2a" />
        {/* Chaussures */}
        <ellipse cx={isFemale ? 35 : 34} cy="149" rx="7" ry="3.5" fill="#111" />
        <ellipse cx={isFemale ? 53 : 54} cy="149" rx="7" ry="3.5" fill="#111" />

        {/* ── Corps ── */}
        <rect x={isFemale ? 26 : 24} y="72" width={isFemale ? 36 : 40} height="42" rx="6" fill="url(#bodyGrad)" />

        {/* ── Bras ── */}
        <rect x={isFemale ? 14 : 11} y="74" width={isFemale ? 11 : 12} height="30" rx="5" fill="url(#bodyGrad)" />
        <rect x={isFemale ? 63 : 65} y="74" width={isFemale ? 11 : 12} height="30" rx="5" fill="url(#bodyGrad)" />
        {/* Mains */}
        <ellipse cx={isFemale ? 19 : 17} cy="106" rx="6" ry="5" fill="#d4956e" />
        <ellipse cx={isFemale ? 69 : 71} cy="106" rx="6" ry="5" fill="#d4956e" />

        {/* ── Cou ── */}
        <rect x="39" y="57" width="10" height="17" rx="4" fill="#d4956e" />

        {/* ── Tête ── */}
        <ellipse cx="44" cy={isFemale ? 44 : 43} rx={isFemale ? 17 : 18} ry={isFemale ? 19 : 20} fill="#d4956e" />

        {/* Cheveux */}
        <path
          d={isFemale
            ? `M27,${44 - hairLen} Q44,${26 - hairLen} 61,${44 - hairLen} Q61,${32 - hairLen} 44,${28 - hairLen} Q27,${32 - hairLen} 27,${44 - hairLen}Z`
            : `M26,${43 - hairLen} Q44,${25 - hairLen} 62,${43 - hairLen} Q62,${31 - hairLen} 44,${27 - hairLen} Q26,${31 - hairLen} 26,${43 - hairLen}Z`
          }
          fill="url(#hairGrad)"
        />
        {/* Mèches latérales si cheveux longs */}
        {hairLen >= 16 && (
          <>
            <rect x="27" y={isFemale ? 38 : 37} width="4" height={hairLen - 4} rx="2" fill={hairColor} />
            <rect x={isFemale ? 57 : 57} y={isFemale ? 38 : 37} width="4" height={hairLen - 4} rx="2" fill={hairColor} />
          </>
        )}

        {/* ── Visage ── */}
        {/* Yeux */}
        <ellipse cx={isFemale ? 39 : 38} cy={isFemale ? 44 : 43} rx="2.2" ry="2.5" fill="#1a1a0a" />
        <ellipse cx={isFemale ? 49 : 50} cy={isFemale ? 44 : 43} rx="2.2" ry="2.5" fill="#1a1a0a" />
        <ellipse cx={isFemale ? 39.7 : 38.7} cy={isFemale ? 43.2 : 42.2} rx="0.7" ry="0.7" fill="#fff" opacity="0.8" />
        <ellipse cx={isFemale ? 49.7 : 50.7} cy={isFemale ? 43.2 : 42.2} rx="0.7" ry="0.7" fill="#fff" opacity="0.8" />

        {/* Sourcils */}
        <path d={isFemale ? "M36 38 Q39 36.5 42 38" : "M34 38 Q38 36 42 38"} stroke="#2c1300" strokeWidth={isFemale ? "0.7" : "1.2"} fill="none" />
        <path d={isFemale ? "M46 38 Q49 36.5 52 38" : "M46 38 Q50 36 54 38"} stroke="#2c1300" strokeWidth={isFemale ? "0.7" : "1.2"} fill="none" />

        {/* Bouche */}
        <path
          d={isFemale ? "M40 52 Q44 55.5 48 52" : "M40 52 Q44 56 48 52"}
          stroke={isFemale ? "#c07060" : "#a06050"}
          strokeWidth={isFemale ? "0.9" : "0.8"}
          fill="none"
          strokeLinecap="round"
        />

        {/* Barbe (masculin uniquement) */}
        {hasBeard && (
          <ellipse cx="44" cy="55" rx="12" ry="7" fill={beardColor} opacity="0.8" />
        )}

        {/* Oreilles */}
        <ellipse cx={isFemale ? 27 : 26} cy={isFemale ? 46 : 45} rx="2.5" ry="3.5" fill="#d4956e" />
        <ellipse cx={isFemale ? 61 : 62} cy={isFemale ? 46 : 45} rx="2.5" ry="3.5" fill="#d4956e" />
      </g>

      {/* Badge sélections */}
      <rect x="4" y="148" width="80" height="10" rx="3" fill="rgba(0,0,0,0.5)" />
      <text x="44" y="155.5" fontSize="6" fontFamily="monospace" textAnchor="middle" fill="rgba(0,217,255,0.5)" letterSpacing="0.3">
        {Object.keys(selections).length} ITEM{Object.keys(selections).length !== 1 ? "S" : ""}
      </text>
    </svg>
  );
}

// ── Props ─────────────────────────────────────────────────────────────────
interface AssetPickerPageProps {
  gender: GenderModel;
  onPreview?: (components: ClothingComponents, props: Props, overlays: HeadOverlays) => void;
  onValidate?: (components: ClothingComponents, props: Props, overlays: HeadOverlays) => void;
  onClearAll?: () => void;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export default function AssetPickerPage({
  gender,
  onPreview,
  onValidate,
  onClearAll,
}: AssetPickerPageProps) {
  // On garde les sélections en local pour la preview SVG
  // Le hook interne d'AssetPicker les gère — on les reçoit via onChange
  const [liveSelections, setLiveSelections] = useLiveSelections();

  const handleChange = useCallback(
    (payload: AssetPayload, selections: PickerSelection) => {
      setLiveSelections(selections);
      onPreview?.(
        payloadToComponents(payload),
        payloadToProps(payload),
        payloadToOverlays(payload)
      );
    },
    [onPreview, setLiveSelections]
  );

  const handleValidate = useCallback(
    (payload: AssetPayload) => {
      onValidate?.(
        payloadToComponents(payload),
        payloadToProps(payload),
        payloadToOverlays(payload)
      );
    },
    [onValidate]
  );

  // Statistiques rapides
  const stats = useMemo(() => {
    const entries = Object.entries(liveSelections);
    const withTex = entries.filter(([, v]) => v.texture > 0).length;
    const withColor = entries.filter(([, v]) => v.color !== undefined && v.color > 0).length;
    return { total: entries.length, withTex, withColor };
  }, [liveSelections]);

  return (
    <div className={styles.wrapper}>
      <div className={styles.layout}>

        {/* ── Mini preview ──────────────────────────────────────────── */}
        <div className={styles.previewCol}>
          <span className={styles.previewLabel}>Aperçu</span>

          <div className={styles.previewSvgWrap}>
            <MiniPreviewSvg gender={gender} selections={liveSelections} />
          </div>

          {/* Stats */}
          <div className={styles.previewStats}>
            <div className={styles.statRow}>
              <span className={styles.statKey}>Items</span>
              <span className={styles.statVal}>{stats.total}</span>
            </div>
            {stats.withTex > 0 && (
              <div className={styles.statRow}>
                <span className={styles.statKey}>Tex</span>
                <span className={styles.statVal}>{stats.withTex}</span>
              </div>
            )}
            {stats.withColor > 0 && (
              <div className={styles.statRow}>
                <span className={styles.statKey}>Coul</span>
                <span className={styles.statVal}>{stats.withColor}</span>
              </div>
            )}
          </div>

          {/* Actions */}
          {onClearAll && stats.total > 0 && (
            <div className={styles.previewActions}>
              <button className={styles.miniBtnDanger} onClick={onClearAll}>
                ✕ Reset
              </button>
            </div>
          )}
        </div>

        {/* ── Asset Picker ──────────────────────────────────────────── */}
        <div className={styles.pickerArea}>
          <AssetPicker
            defaultGender={gender}
            assetBasePath="./assets"
            onChange={handleChange}
            onValidate={handleValidate}
          />
        </div>

      </div>
    </div>
  );
}

// ── Hook local pour les sélections live ───────────────────────────────────
import { useState } from "react";

function useLiveSelections(): [PickerSelection, (s: PickerSelection) => void] {
  const [sel, setSel] = useState<PickerSelection>({});
  return [sel, setSel];
}