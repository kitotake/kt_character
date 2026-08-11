// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// IdentityWindow — fenêtre 1/2, indépendante
// Prénom / Nom / Date de naissance / Sexe → bouton Continuer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useState, useCallback } from "react";
import styles from "./IdentityWindow.module.scss";
import Category   from "../../components/Category/Category";
import Field      from "../../components/Field/Field";
import DateField  from "../../components/DateField/DateField";
import type { IdentityData } from "../../hooks/useCreator";

// Durée de l'animation de sortie (doit correspondre à la transition scss du .container)
const CLOSE_TRANSITION_MS = 220;

interface IdentityWindowProps {
  identity: IdentityData;
  errors: Record<string, string>;
  serverError: string;
  getAge: () => number | null;
  updateIdentity: (key: keyof IdentityData, value: string) => void;
  onContinue: () => void;
  onClose: () => void;
}

export default function IdentityWindow({
  identity, errors, serverError, getAge,
  updateIdentity, onContinue, onClose,
}: IdentityWindowProps) {
  // Fermeture de CETTE fenêtre avant l'ouverture de ClothingWindow : on
  // joue l'animation de sortie ici (déclenchée depuis le handler de clic,
  // pas dans un effect), puis on prévient le parent que la phase peut
  // basculer une fois la fenêtre visuellement fermée.
  const [closing, setClosing] = useState(false);

  const handleContinue = useCallback(() => {
    if (closing) return;
    setClosing(true);
    setTimeout(onContinue, CLOSE_TRANSITION_MS);
  }, [closing, onContinue]);

  return (
    <div className={[styles.container, closing ? styles.closing : ""].join(" ")}>

      {/* ── Header ── */}
      <div className={styles.header}>
        <h2 className={styles.title}>
          <span>👤</span>
          Identité
        </h2>
        <button
          type="button"
          className={styles.closeBtn}
          onClick={onClose}
          disabled={closing}
          aria-label="Fermer"
        >
          ×
        </button>
      </div>

      {/* ── Erreur serveur ── */}
      {serverError && <div className={styles.error}>{serverError}</div>}

      {/* ── Body ── */}
      <div className={styles.body}>
        <Category title="État civil" icon="👤">
          <Field
            label="Prénom"
            type="text"
            value={identity.firstname}
            onChange={(v) => updateIdentity("firstname", v)}
            placeholder="ex: Jean"
            required
            error={errors.firstname}
            disabled={closing}
          />
          <Field
            label="Nom"
            type="text"
            value={identity.lastname}
            onChange={(v) => updateIdentity("lastname", v)}
            placeholder="ex: Dupont"
            required
            error={errors.lastname}
            disabled={closing}
          />
          <DateField
            label={`Date de naissance${getAge() !== null ? ` — ${getAge()} ans` : ""}`}
            value={identity.dateofbirth}
            onChange={(v) => updateIdentity("dateofbirth", v)}
            required
            error={errors.dateofbirth}
            disabled={closing}
          />
        </Category>

        <Category title="Genre" icon="⚧">
          <div className={styles.genderRow}>
            <button
              className={[
                styles.genderBtn,
                identity.gender === "mp_m_freemode_01" ? styles.genderActive : "",
              ].join(" ")}
              onClick={() => updateIdentity("gender", "mp_m_freemode_01")}
              disabled={closing}
            >
              <span className={styles.genderIcon}>♂</span>
              <span className={styles.genderLabel}>Masculin</span>
              <span className={styles.genderSub}>mp_m</span>
            </button>
            <button
              className={[
                styles.genderBtn,
                identity.gender === "mp_f_freemode_01" ? styles.genderActive : "",
              ].join(" ")}
              onClick={() => updateIdentity("gender", "mp_f_freemode_01")}
              disabled={closing}
            >
              <span className={styles.genderIcon}>♀</span>
              <span className={styles.genderLabel}>Féminin</span>
              <span className={styles.genderSub}>mp_f</span>
            </button>
          </div>
        </Category>
      </div>

      {/* ── Footer ── */}
      <div className={styles.footer}>
        <button className={styles.continueBtn} onClick={handleContinue} disabled={closing}>
          Continuer →
        </button>
      </div>

    </div>
  );
}
