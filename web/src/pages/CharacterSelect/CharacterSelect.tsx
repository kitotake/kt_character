// web/src/pages/CharacterSelect.tsx
// Sélection de personnage avec previews visuelles SVG inline
// FIX: TS6133 — suppression des vars 'health' et 'isFemale' inutilisées dans CharacterSilhouette

import { useState, useEffect, useCallback } from "react";
import styles from "./CharacterSelect.module.scss";

interface Character {
  id: number;
  unique_id: string;
  firstname: string;
  lastname: string;
  dateofbirth: string;
  gender: string;
  model: string;
  job: string;
  job_grade: number;
  health: number;
  armor: number;
}

interface CharacterSelectProps {
  visible: boolean;
  characters: Character[];
  slots: number;
}

function getAge(dateofbirth: string): number {
  const dob = new Date(dateofbirth);
  const diff = Date.now() - dob.getTime();
  return Math.floor(diff / (1000 * 60 * 60 * 24 * 365.25));
}

// ─── Silhouette SVG générée selon genre + job ────────────────────────────
// FIX: supprimé 'health' et 'isFemale' non utilisés dans ce composant
function CharacterSilhouette({
  gender,
  job,
  selected,
}: {
  gender: string;
  job: string;
  selected: boolean;
}) {
  const jobColors: Record<
    string,
    { primary: string; secondary: string; accent: string }
  > = {
    police:    { primary: "#1a2a4a", secondary: "#2a4080", accent: "#4a90d9" },
    ambulance: { primary: "#1a3a2a", secondary: "#1e7a3a", accent: "#4adb7a" },
    mechanic:  { primary: "#2a1a0a", secondary: "#5a3010", accent: "#d97a20" },
    unemployed:{ primary: "#1a1a2a", secondary: "#2a2a3a", accent: "#7a7aaa" },
    default:   { primary: "#1a1a2a", secondary: "#2a2a3a", accent: "#00d9ff" },
  };

  const jobKey = job?.toLowerCase() ?? "default";
  const colors = jobColors[jobKey] ?? jobColors.default;

  return (
    <svg
      viewBox="0 0 120 200"
      xmlns="http://www.w3.org/2000/svg"
      className={styles.silhouette}
    >
      <defs>
        <linearGradient id={`bg-${gender}-${jobKey}`} x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor={colors.primary} />
          <stop offset="100%" stopColor="#0a0a12" />
        </linearGradient>
        <linearGradient id={`body-${gender}-${jobKey}`} x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={colors.secondary} />
          <stop offset="100%" stopColor={colors.primary} />
        </linearGradient>
        <radialGradient id={`glow-${gender}-${jobKey}`} cx="50%" cy="30%" r="50%">
          <stop offset="0%" stopColor={colors.accent} stopOpacity="0.15" />
          <stop offset="100%" stopColor={colors.accent} stopOpacity="0" />
        </radialGradient>
      </defs>

      <rect width="120" height="200" fill={`url(#bg-${gender}-${jobKey})`} />
      <rect width="120" height="200" fill={`url(#glow-${gender}-${jobKey})`} />

      {selected && (
        <>
          <rect width="120" height="200" fill="none" stroke={colors.accent} strokeWidth="2.5" opacity="0.9" />
          <rect width="120" height="200" fill={colors.accent} opacity="0.05" />
        </>
      )}
    </svg>
  );
}

// ─── Slot vide ─────────────────────────────────────────────────────────────
function EmptySlotSvg() {
  return (
    <svg viewBox="0 0 120 200" xmlns="http://www.w3.org/2000/svg" className={styles.silhouette}>
      <defs>
        <linearGradient id="emptyBg" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stopColor="#12121a" />
          <stop offset="100%" stopColor="#0a0a10" />
        </linearGradient>
      </defs>
      <rect width="120" height="200" fill="url(#emptyBg)" />
      <g opacity="0.08" fill="none" stroke="#00d9ff" strokeWidth="1.5" strokeDasharray="4 3">
        <ellipse cx="60" cy="58" rx="22" ry="26" />
        <rect x="36" y="88" width="48" height="52" rx="6" />
        <rect x="22" y="90" width="14" height="40" rx="5" />
        <rect x="84" y="90" width="14" height="40" rx="5" />
        <rect x="42" y="140" width="15" height="45" rx="4" />
        <rect x="63" y="140" width="15" height="45" rx="4" />
      </g>
      <circle cx="60" cy="95" r="18" fill="none" stroke="rgba(0,217,255,0.15)" strokeWidth="1" />
      <line x1="60" y1="86" x2="60" y2="104" stroke="rgba(0,217,255,0.25)" strokeWidth="2" strokeLinecap="round" />
      <line x1="51" y1="95" x2="69" y2="95" stroke="rgba(0,217,255,0.25)" strokeWidth="2" strokeLinecap="round" />
      <text x="60" y="125" fontSize="7.5" fontFamily="monospace" textAnchor="middle" fill="rgba(0,217,255,0.3)" letterSpacing="0.5">LIBRE</text>
    </svg>
  );
}

// ─── Card personnage ─────────────────────────────────────────────────────
function CharacterCard({
  char,
  selected,
  onClick,
}: {
  char: Character;
  selected: boolean;
  onClick: () => void;
}) {
  const age = char.dateofbirth ? getAge(char.dateofbirth) : null;
  const isFemale = char.gender === "f" || char.gender === "mp_f_freemode_01";
  const hp = Math.max(0, Math.min(100, ((char.health - 100) / 100) * 100));
  const hpColor = hp > 60 ? "#10b981" : hp > 30 ? "#f59e0b" : "#ef4444";

  return (
    <button
      className={[styles.card, selected ? styles.cardSelected : ""].join(" ")}
      onClick={onClick}
    >
      <div className={styles.cardVisual}>
        <CharacterSilhouette
          gender={char.gender}
          job={char.job}
          selected={selected}
        />
        {selected && <div className={styles.selectedBadge}>✓</div>}
      </div>

      <div className={styles.cardInfo}>
        <div className={styles.cardName}>
          {char.firstname} {char.lastname}
        </div>
        <div className={styles.cardMeta}>
          <span className={styles.genderIcon}>{isFemale ? "♀" : "♂"}</span>
          {age !== null && <span>{age} ans</span>}
        </div>
        {char.job && (
          <div className={styles.jobBadge}>
            {char.job === "unemployed" ? "Sans emploi" : char.job}
            {char.job_grade > 0 && <span className={styles.jobGrade}> G{char.job_grade}</span>}
          </div>
        )}
        <div className={styles.hpRow}>
          <div className={styles.hpBar}>
            <div className={styles.hpFill} style={{ width: `${hp}%`, background: hpColor }} />
          </div>
          <span className={styles.hpValue}>{Math.round(hp)}%</span>
        </div>
      </div>
    </button>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────
export default function CharacterSelect({ visible, characters, slots }: CharacterSelectProps) {
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!visible) {
      setSelectedId(null);
      setLoading(false);
      setError("");
    }
  }, [visible]);

  const handlePlay = useCallback(async () => {
    if (selectedId === null) {
      setError("Veuillez sélectionner un personnage.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const resourceName = (window as any).GetParentResourceName?.() ?? "kt_character";
      const res = await fetch(`https://${resourceName}/selectCharacter`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ charId: selectedId }),
      });
      if (!res.ok) {
        setError("Erreur lors de la sélection.");
        setLoading(false);
      }
    } catch {
      setError("Connexion perdue.");
      setLoading(false);
    }
  }, [selectedId]);

  if (!visible) return null;

  const usedSlots = characters.length;
  const totalSlots = slots;
  const selectedChar = characters.find((c) => c.id === selectedId);

  return (
    <div className={styles.overlay}>
      <div className={styles.panel}>
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <h2 className={styles.title}>Choisir un personnage</h2>
            <div className={styles.slotRow}>
              {Array.from({ length: totalSlots }, (_, i) => (
                <div
                  key={i}
                  className={[
                    styles.slotDot,
                    i < usedSlots ? styles.slotDotFilled : styles.slotDotEmpty,
                  ].join(" ")}
                  title={i < usedSlots ? "Occupé" : "Libre"}
                />
              ))}
              <span className={styles.slotsText}>{usedSlots}/{totalSlots} slots</span>
            </div>
          </div>
        </div>

        <div
          className={styles.grid}
          style={{ gridTemplateColumns: `repeat(${Math.min(totalSlots, 4)}, 1fr)` }}
        >
          {characters.map((char) => (
            <CharacterCard
              key={char.id}
              char={char}
              selected={selectedId === char.id}
              onClick={() => setSelectedId(char.id)}
            />
          ))}
          {Array.from({ length: Math.max(0, totalSlots - usedSlots) }, (_, i) => (
            <div key={`empty-${i}`} className={styles.emptySlot}>
              <EmptySlotSvg />
              <span className={styles.emptyLabel}>Slot libre</span>
            </div>
          ))}
        </div>

        {error && <div className={styles.error}>{error}</div>}

        <div className={styles.footer}>
          <div className={styles.selectedInfo}>
            {selectedChar ? (
              <>
                <span className={styles.selectedName}>{selectedChar.firstname} {selectedChar.lastname}</span>
                <span className={styles.selectedMeta}>
                  {selectedChar.job !== "unemployed" ? selectedChar.job : "Sans emploi"}
                </span>
              </>
            ) : (
              <span className={styles.hint}>Cliquez sur un personnage pour le sélectionner</span>
            )}
          </div>
          <button className={styles.playBtn} onClick={handlePlay} disabled={selectedId === null || loading}>
            {loading ? "⏳ Chargement..." : "▶ Jouer"}
          </button>
        </div>
      </div>
    </div>
  );
}