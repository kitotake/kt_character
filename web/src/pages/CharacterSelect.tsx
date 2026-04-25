// web/src/pages/CharacterSelect.tsx

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

function GenderIcon({ gender }: { gender: string }) {
  return (
    <span className={styles.genderIcon}>
      {gender === "f" || gender === "mp_f_freemode_01" ? "♀" : "♂"}
    </span>
  );
}

function HealthBar({ value, max = 200 }: { value: number; max?: number }) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  const color =
    pct > 60 ? "var(--color-text-success)" :
    pct > 30 ? "var(--color-text-warning)" :
               "var(--color-text-danger)";
  return (
    <div className={styles.healthBar}>
      <div
        className={styles.healthFill}
        style={{ width: `${pct}%`, background: color }}
      />
    </div>
  );
}

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
  const isMale = char.gender !== "f" && char.gender !== "mp_f_freemode_01";

  return (
    <button
      className={[styles.card, selected ? styles.cardSelected : ""].join(" ")}
      onClick={onClick}
    >
      <div className={styles.cardAvatar}>
        <span className={styles.avatarEmoji}>{isMale ? "🧑" : "👩"}</span>
      </div>

      <div className={styles.cardBody}>
        <div className={styles.cardName}>
          {char.firstname} {char.lastname}
        </div>

        <div className={styles.cardMeta}>
          <GenderIcon gender={char.gender} />
          {age !== null && <span>{age} ans</span>}
          {char.dateofbirth && (
            <span className={styles.dob}>{char.dateofbirth}</span>
          )}
        </div>

        <div className={styles.cardJob}>
          <span className={styles.jobLabel}>
            {char.job || "unemployed"}
          </span>
          {char.job_grade > 0 && (
            <span className={styles.jobGrade}>Grade {char.job_grade}</span>
          )}
        </div>

        <div className={styles.cardStats}>
          <div className={styles.statRow}>
            <span className={styles.statLabel}>HP</span>
            <HealthBar value={char.health} />
            <span className={styles.statValue}>{Math.max(0, char.health - 100)}/100</span>
          </div>
          {char.armor > 0 && (
            <div className={styles.statRow}>
              <span className={styles.statLabel}>Armure</span>
              <HealthBar value={char.armor} max={100} />
              <span className={styles.statValue}>{char.armor}</span>
            </div>
          )}
        </div>
      </div>

      {selected && <div className={styles.selectedBadge}>✓</div>}
    </button>
  );
}

export default function CharacterSelect({
  visible,
  characters,
  slots,
}: CharacterSelectProps) {
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [loading, setLoading]       = useState(false);
  const [error, setError]           = useState("");

  useEffect(() => {
    if (!visible) {
      setSelectedId(null);
      setLoading(false);
      setError("");
    }
  }, [visible]);

  // FIX: utilise le NUI callback "selectCharacter" déclaré dans client/main.lua
  // au lieu d'un fetch direct vers "selectCharacter" (qui n'est pas enregistré)
  const handlePlay = useCallback(async () => {
    if (selectedId === null) {
      setError("Veuillez sélectionner un personnage.");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const resourceName =
        (window as any).GetParentResourceName?.() ?? "kt_character";

      // FIX: endpoint = "selectCharacter" → correspond au RegisterNUICallback
      // dans client/main.lua qui relaie vers kt_character:selectCharacter
      const res = await fetch(`https://${resourceName}/selectCharacter`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ charId: selectedId }),
      });

      if (!res.ok) {
        setError("Erreur lors de la sélection.");
        setLoading(false);
        return;
      }

      // La NUI sera fermée par le serveur via union:spawn:apply
      // qui envoie action="close" au client
    } catch {
      setError("Connexion perdue.");
      setLoading(false);
    }
  }, [selectedId]);

  if (!visible) return null;

  const usedSlots  = characters.length;
  const totalSlots = slots;

  return (
    <div className={styles.overlay}>
      <div className={styles.panel}>
        {/* Header */}
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <h2 className={styles.title}>Choisir un personnage</h2>
            <span className={styles.slots}>
              {usedSlots} / {totalSlots} emplacements
            </span>
          </div>

          <div className={styles.slotDots}>
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
          </div>
        </div>

        {/* Character grid */}
        <div className={styles.grid}>
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
              <span className={styles.emptyIcon}>+</span>
              <span className={styles.emptyLabel}>Emplacement libre</span>
            </div>
          ))}
        </div>

        {error && <div className={styles.error}>{error}</div>}

        {/* Footer */}
        <div className={styles.footer}>
          <div className={styles.selectedInfo}>
            {selectedId !== null ? (
              <span>
                Sélectionné :{" "}
                <strong>
                  {characters.find((c) => c.id === selectedId)?.firstname}{" "}
                  {characters.find((c) => c.id === selectedId)?.lastname}
                </strong>
              </span>
            ) : (
              <span className={styles.hintText}>
                Cliquez sur un personnage pour le sélectionner
              </span>
            )}
          </div>

          <button
            className={styles.playBtn}
            onClick={handlePlay}
            disabled={selectedId === null || loading}
          >
            {loading ? "⏳ Chargement..." : "▶ Jouer"}
          </button>
        </div>
      </div>
    </div>
  );
}