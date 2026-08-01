// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Creator.tsx — Wizard identité + tenue
// SCSS propre : Creator.module.scss (wizard) / AssetPickerPage.module.scss (tenue)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import styles from "./Creator.module.scss";
import { useCreator, STEPS } from "../../hooks/useCreator";
import Category        from "../../components/Category/Category";
import Field           from "../../components/Field/Field";
import AssetPickerPage from "../AssetPickerPage/AssetPickerPage";

// ─── Boutons caméra ───────────────────────────────────────────────────────
const CAM_BUTTONS = [
  { action: "rotateLeft",  icon: "↺", label: "Gauche" },
  { action: "rotateRight", icon: "↻", label: "Droite" },
  { action: "zoomIn",      icon: "⊕", label: "Zoom +" },
  { action: "zoomOut",     icon: "⊖", label: "Zoom -" },
  { action: "focusHead",   icon: "◯", label: "Tête"   },
  { action: "focusBody",   icon: "▭", label: "Corps"  },
  { action: "focusFull",   icon: "▬", label: "Entier" },
  { action: "resetCam",    icon: "⌖", label: "Reset"  },
] as const;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export default function Creator() {
  const {
    visible, stepIndex, errors, serverError, submitting, isLastStep, currentStep,
    identity,
    closeUI, goToStep, nextStep, prevStep, handleSubmit, camControl, getAge,
    updateIdentity, updateComponents, updateProps, updateHeadOverlays,
  } = useCreator();

  if (!visible) return null;

  const ACTIVE_STEPS = STEPS.filter((s) => s.id === "identity" || s.id === "clothing");
  const activeIndex    = ACTIVE_STEPS.findIndex((s) => s.id === currentStep.id);
  const isClothingStep = currentStep.id === "clothing";

  return (
    <>
      {/* ── Panneau caméra ───────────────────────────────────────────── */}
      <div className={styles.camPanel}>
        <span className={styles.camTitle}>CAMÉRA</span>
        {CAM_BUTTONS.map((btn) => (
          <button
            key={btn.action}
            className={styles.camBtn}
            title={btn.label}
            onClick={() => camControl(btn.action)}
          >
            <span className={styles.camIcon}>{btn.icon}</span>
            <span className={styles.camLabel}>{btn.label}</span>
          </button>
        ))}
      </div>

      {/* ── Panneau principal ─────────────────────────────────────────── */}
      <div className={styles.container}>

        {/* ── Barre de progression ── */}
        <div className={styles.stepBar}>
          {ACTIVE_STEPS.map((s, i) => (
            <button
              key={s.id}
              className={[
                styles.stepDot,
                s.id === currentStep.id ? styles.stepActive : "",
                i < activeIndex         ? styles.stepDone   : "",
              ].join(" ")}
              onClick={() => i < activeIndex && goToStep(STEPS.findIndex((x) => x.id === s.id))}
              title={s.label}
            >
              <span className={styles.stepDotIcon}>
                {i < activeIndex ? "✓" : s.icon}
              </span>
              <span className={styles.stepDotLabel}>{s.label}</span>
            </button>
          ))}
        </div>

        {/* ── Header étape ── */}
        <div className={styles.stepHeader}>
          <span className={styles.stepNum}>{activeIndex + 1}/{ACTIVE_STEPS.length}</span>
          <h2 className={styles.stepTitle}>
            <span>{currentStep.icon}</span>
            {currentStep.label}
          </h2>
          <button
            type="button"
            className={styles.closeBtn}
            onClick={() => void closeUI()}
            disabled={submitting}
            aria-label="Fermer"
          >
            ×
          </button>
        </div>

        {/* ── Erreur serveur ── */}
        {serverError && (
          <div className={styles.error}>{serverError}</div>
        )}

        {/* ── Contenu scrollable ──
            Sur l'étape clothing on retire le padding pour que
            AssetPickerPage occupe tout l'espace ── */}
        <div className={[
          styles.stepContent,
          isClothingStep ? styles.noPad : "",
        ].join(" ")}>

          {/* ÉTAPE 1 — IDENTITÉ */}
          {currentStep.id === "identity" && (
            <>
              <Category title="État civil" icon="👤">
                <Field
                  label="Prénom"
                  type="text"
                  value={identity.firstname}
                  onChange={(v) => updateIdentity("firstname", v)}
                  placeholder="ex: Jean"
                  required
                  error={errors.firstname}
                />
                <Field
                  label="Nom"
                  type="text"
                  value={identity.lastname}
                  onChange={(v) => updateIdentity("lastname", v)}
                  placeholder="ex: Dupont"
                  required
                  error={errors.lastname}
                />
                <Field
                  label={`Date de naissance${getAge() !== null ? ` — ${getAge()} ans` : ""}`}
                  type="date"
                  value={identity.dateofbirth}
                  onChange={(v) => updateIdentity("dateofbirth", v)}
                  required
                  error={errors.dateofbirth}
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
                  >
                    <span className={styles.genderIcon}>♀</span>
                    <span className={styles.genderLabel}>Féminin</span>
                    <span className={styles.genderSub}>mp_f</span>
                  </button>
                </div>
              </Category>
            </>
          )}

          {/* ÉTAPE 2 — TENUE */}
          {currentStep.id === "clothing" && (
            <AssetPickerPage
              gender={identity.gender}
              onPreview={(comps, prps, overlays) => {
                updateComponents(comps);
                updateProps(prps);
                updateHeadOverlays(overlays);
              }}
              onValidate={(comps, prps, overlays) => {
                updateComponents(comps);
                updateProps(prps);
                updateHeadOverlays(overlays);
                if (!isLastStep) nextStep();
                else void handleSubmit();
              }}
              onClearAll={() => {
                updateComponents({});
                updateProps({});
              }}
            />
          )}
        </div>

        {/* ── Navigation ── */}
        <div className={styles.navRow}>
          <button
            className={styles.navBtn}
            onClick={prevStep}
            disabled={stepIndex === 0 || submitting}
          >
            ← Retour
          </button>

          {/* Étape identité → Suivant */}
          {!isClothingStep && !isLastStep && (
            <button className={styles.navBtnNext} onClick={nextStep}>
              Suivant →
            </button>
          )}

          {/* Étape clothing si dernière → Créer */}
          {isClothingStep && isLastStep && (
            <button
              className={styles.submitBtn}
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? "⏳ Création..." : "✓ Créer le personnage"}
            </button>
          )}

          {/* Étape identité si dernière (cas edge) → Créer */}
          {!isClothingStep && isLastStep && (
            <button
              className={styles.submitBtn}
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? "⏳ Création..." : "✓ Créer le personnage"}
            </button>
          )}
        </div>

      </div>
    </>
  );
}
