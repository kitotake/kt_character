// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DateField — saisie masquée JJ/MM/AAAA (placeholder 00/00/0000)
// Expose toujours une valeur ISO (yyyy-mm-dd) au parent : c'est le format
// attendu par identity.dateofbirth (validation front + Lua serveur), donc
// aucune autre logique n'a besoin de changer, seul l'affichage est masqué.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useState, useCallback } from "react";
import type { KeyboardEvent } from "react";
import styles from "./DateField.module.scss";

interface DateFieldProps {
  label: string;
  value: string; // ISO yyyy-mm-dd, ou ""
  onChange: (isoValue: string) => void;
  required?: boolean;
  error?: string;
  hint?: string;
  disabled?: boolean;
}

// yyyy-mm-dd → "ddmmyyyy" (chiffres bruts)
function isoToDigits(iso: string): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
  return m ? `${m[3]}${m[2]}${m[1]}` : "";
}

// "ddmmyyyy" → yyyy-mm-dd (uniquement une fois les 8 chiffres saisis)
function digitsToIso(digits: string): string {
  if (digits.length !== 8) return "";
  const d = digits.slice(0, 2);
  const m = digits.slice(2, 4);
  const y = digits.slice(4, 8);
  return `${y}-${m}-${d}`;
}

// "ddmmyyyy" → "dd/mm/yyyy" progressif pour l'affichage
function digitsToDisplay(digits: string): string {
  return [digits.slice(0, 2), digits.slice(2, 4), digits.slice(4, 8)]
    .filter(Boolean)
    .join("/");
}

export default function DateField({ label, value, onChange, required, error, hint, disabled }: DateFieldProps) {
  // La valeur externe ne change jamais que suite au onChange de ce composant
  // lui-même dans cette app (identity.dateofbirth n'est réinitialisé nulle
  // part ailleurs) : un simple état initial paresseux suffit, pas besoin
  // d'un effect de resynchronisation.
  const [digits, setDigits] = useState<string>(() => isoToDigits(value));

  const handleChange = useCallback((raw: string) => {
    const onlyDigits = raw.replace(/\D/g, "").slice(0, 8);
    setDigits(onlyDigits);
    onChange(digitsToIso(onlyDigits));
  }, [onChange]);

  const handleKeyDown = useCallback((e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key.length === 1 && !/\d/.test(e.key)) {
      e.preventDefault();
    }
  }, []);

  return (
    <div className={styles.wrapper}>
      <label className={styles.label}>
        {label}
        {required && <span className={styles.required}>*</span>}
      </label>
      <input
        className={styles.input}
        type="text"
        inputMode="numeric"
        autoComplete="bday"
        maxLength={10}
        placeholder="00/00/0000"
        value={digitsToDisplay(digits)}
        disabled={disabled}
        onKeyDown={handleKeyDown}
        onChange={(e) => handleChange(e.target.value)}
      />
      {hint && !error && <span className={styles.hint}>{hint}</span>}
      {error && <span className={styles.error}>{error}</span>}
    </div>
  );
}
