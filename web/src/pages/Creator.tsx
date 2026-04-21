// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Creator.tsx — Rendu pur, AUCUNE logique métier
// Toute la logique est dans hooks/useCreator.ts
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import styles from "./Creator.module.scss";
import { useCreator, STEPS } from "../hooks/useCreator";

import Slider       from "../components/Slider/Slider";
import Category     from "../components/Category/Category";
import ColorPicker  from "../components/ColorPicker/ColorPicker";
import Field        from "../components/Field/Field";
import Parents      from "../components/Parents/Parents";
import FaceFeatures from "../components/FaceFeatures/FaceFeatures";
import HeadOverlays from "../components/HeadOverlays/HeadOverlays";
import Clothing     from "../components/Clothing/Clothing";
import Tattoos      from "../components/Tattoos/Tattoos";

// ─── Boutons caméra ───────────────────────────────────────────────────────
const CAM_BUTTONS = [
  { action: "rotateLeft",  icon: "↺", label: "Gauche",  title: "Tourner à gauche" },
  { action: "rotateRight", icon: "↻", label: "Droite",  title: "Tourner à droite" },
  { action: "zoomIn",      icon: "⊕", label: "Zoom +",  title: "Zoom avant"       },
  { action: "zoomOut",     icon: "⊖", label: "Zoom -",  title: "Zoom arrière"     },
  { action: "focusHead",   icon: "◯", label: "Tête",    title: "Focus visage"     },
  { action: "focusBody",   icon: "▭", label: "Corps",   title: "Focus corps"      },
  { action: "focusFull",   icon: "▬", label: "Entier",  title: "Vue entière"      },
  { action: "resetCam",    icon: "⌖", label: "Reset",   title: "Réinitialiser"    },
];

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export default function Creator() {
  const {
    visible, stepIndex, errors, serverError, submitting, isLastStep, currentStep,
    identity, headBlend, faceFeatures, headOverlays, hair, components, props, tattoos,
    closeUI, goToStep, nextStep, prevStep, handleSubmit, camControl, getAge,
    updateIdentity, updateHeadBlend, updateFaceFeatures, updateHeadOverlays,
    updateHair, updateComponents, updateProps, updateTattoos,
  } = useCreator();

  if (!visible) return null;

  return (
    <>
      {/* ── Panneau caméra ─────────────────────────────────────────────── */}
      <div className={styles.camPanel}>
        <span className={styles.camTitle}>CAMÉRA</span>
        {CAM_BUTTONS.map((btn) => (
          <button
            key={btn.action}
            className={styles.camBtn}
            title={btn.title}
            onClick={() => camControl(btn.action)}
          >
            <span className={styles.camIcon}>{btn.icon}</span>
            <span className={styles.camLabel}>{btn.label}</span>
          </button>
        ))}
      </div>

      {/* ── Panneau principal ───────────────────────────────────────────── */}
      <div className={styles.container}>

        {/* Step progress bar */}
        <div className={styles.stepBar}>
          {STEPS.map((s, i) => (
            <button
              key={s.id}
              className={[
                styles.stepDot,
                i === stepIndex ? styles.stepActive : "",
                i < stepIndex  ? styles.stepDone   : "",
              ].join(" ")}
              onClick={() => i < stepIndex && goToStep(i)}
              title={s.label}
            >
              <span className={styles.stepDotIcon}>{i < stepIndex ? "✓" : s.icon}</span>
              <span className={styles.stepDotLabel}>{s.label}</span>
            </button>
          ))}
          <div
            className={styles.stepProgress}
            style={{ width: `${(stepIndex / (STEPS.length - 1)) * 100}%` }}
          />
        </div>

        {/* Step header */}
        <div className={styles.stepHeader}>
          <span className={styles.stepNum}>{stepIndex + 1} / {STEPS.length}</span>
          <h2 className={styles.stepTitle}>
            <span>{currentStep.icon}</span> {currentStep.label}
          </h2>
          <button
            type="button"
            className={styles.closeBtn}
            onClick={() => void closeUI()}
            disabled={submitting}
            title="Fermer"
          >
            ×
          </button>
        </div>

        {/* Messages */}
        {serverError && <div className={styles.error}>{serverError}</div>}

        {/* ── Contenu de l'étape ──────────────────────────────────────── */}
        <div className={styles.stepContent}>

          {currentStep.id === "identity" && (
            <>
              <Category title="État civil" icon="👤">
                <Field
                  label="Prénom" type="text" value={identity.firstname}
                  onChange={(v) => updateIdentity("firstname", v)}
                  placeholder="ex: Jean" required error={errors.firstname}
                />
                <Field
                  label="Nom" type="text" value={identity.lastname}
                  onChange={(v) => updateIdentity("lastname", v)}
                  placeholder="ex: Dupont" required error={errors.lastname}
                />
                <Field
                  label={`Date de naissance${getAge() ? ` (${getAge()} ans)` : ""}`}
                  type="date" value={identity.dateofbirth}
                  onChange={(v) => updateIdentity("dateofbirth", v)}
                  required error={errors.dateofbirth}
                />
              </Category>

              <Category title="Genre" icon="⚧">
                <div className={styles.genderRow}>
                  <button
                    className={[styles.genderBtn, identity.gender === "mp_m_freemode_01" ? styles.genderActive : ""].join(" ")}
                    onClick={() => updateIdentity("gender", "mp_m_freemode_01")}
                  >
                    <span className={styles.genderIcon}>♂</span>
                    <span className={styles.genderLabel}>Masculin</span>
                    <span className={styles.genderSub}>mp_m</span>
                  </button>
                  <button
                    className={[styles.genderBtn, identity.gender === "mp_f_freemode_01" ? styles.genderActive : ""].join(" ")}
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

          {currentStep.id === "parents" && (
            <Category title="Mélange parental" icon="🧬">
              <Parents data={headBlend} onChange={updateHeadBlend} />
            </Category>
          )}

          {currentStep.id === "features" && (
            <Category title="Traits du visage" icon="◉">
              <FaceFeatures data={faceFeatures} onChange={updateFaceFeatures} />
            </Category>
          )}

          {currentStep.id === "overlays" && (
            <Category title="Overlays" icon="🎨">
              <HeadOverlays data={headOverlays} onChange={updateHeadOverlays} />
            </Category>
          )}

          {currentStep.id === "hair" && (
            <>
              <Category title="Coiffure" icon="✦">
                <Slider label="Style" min={0} max={75} value={hair.style}
                  onChange={(v) => updateHair({ style: v })} />
              </Category>
              <Category title="Couleur principale" icon="🎨">
                <ColorPicker label="Couleur" value={hair.color}
                  onChange={(v) => updateHair({ color: v })} />
              </Category>
              <Category title="Reflet / Highlight" icon="✨">
                <ColorPicker label="Reflet" value={hair.highlight}
                  onChange={(v) => updateHair({ highlight: v })} />
              </Category>
            </>
          )}

          {currentStep.id === "clothing" && (
            <Category title="Vêtements & Accessoires" icon="👔">
              <Clothing
                components={components} props={props}
                onChangeComponents={updateComponents}
                onChangeProps={updateProps}
              />
            </Category>
          )}

          {currentStep.id === "tattoos" && (
            <Category title="Tatouages" icon="💉">
              <Tattoos applied={tattoos} onChange={updateTattoos} />
            </Category>
          )}

        </div>

        {/* ── Navigation ──────────────────────────────────────────────── */}
        <div className={styles.navRow}>
          <button
            className={styles.navBtn}
            onClick={prevStep}
            disabled={stepIndex === 0 || submitting}
          >
            ← Retour
          </button>

          {isLastStep ? (
            <button
              className={styles.submitBtn}
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? "⏳ Création..." : "✓ Créer le personnage"}
            </button>
          ) : (
            <button className={styles.navBtnNext} onClick={nextStep}>
              Suivant →
            </button>
          )}
        </div>

      </div>
    </>
  );
}