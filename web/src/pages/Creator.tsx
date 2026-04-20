import styles from "./Creator.module.scss";
import { useState, useCallback, useEffect } from "react";

import Slider       from "../components/Slider/Slider";
import Category     from "../components/Category/Category";
import ColorPicker  from "../components/ColorPicker/ColorPicker";
import Field        from "../components/Field/Field";
import Parents      from "../components/Parents/Parents";
import FaceFeatures from "../components/FaceFeatures/FaceFeatures";
import HeadOverlays from "../components/HeadOverlays/HeadOverlays";
import Clothing     from "../components/Clothing/Clothing";
import Tattoos      from "../components/Tattoos/Tattoos";

import {
  DEFAULT_HEAD_BLEND,
  DEFAULT_FACE_FEATURES,
  DEFAULT_HEAD_OVERLAYS,
  DEFAULT_COMPONENTS,
  DEFAULT_PROPS,
} from "../types/appearance.types";
import type {
  HeadBlend,
  FaceFeatures as FaceFeaturesType,
  HeadOverlays as HeadOverlaysType,
  ClothingComponents,
  Props,
  Tattoo,
} from "../types/appearance.types";

// ─── Steps ────────────────────────────────────────────────────────────────
const STEPS = [
  { id: "identity", label: "Identité",   icon: "👤", tab: "identity" },
  { id: "parents",  label: "Parents",    icon: "🧬", tab: "parents"  },
  { id: "features", label: "Traits",     icon: "◉",  tab: "features" },
  { id: "overlays", label: "Overlays",   icon: "🎨", tab: "overlays" },
  { id: "hair",     label: "Cheveux",    icon: "✦",  tab: "hair"     },
  { id: "clothing", label: "Tenue",      icon: "👔", tab: "clothing" },
  { id: "tattoos",  label: "Tatouages",  icon: "💉", tab: "tattoos"  },
];

interface IdentityData {
  identifier:  string;
  unique_id:   string;
  firstname:   string;
  lastname:    string;
  dateofbirth: string;
  gender: "mp_m_freemode_01" | "mp_f_freemode_01";
}

function validateIdentity(identity: IdentityData): Record<string, string> {
  const errors: Record<string, string> = {};
  if (!identity.firstname.trim())         errors.firstname = "Le prénom est requis";
  else if (identity.firstname.trim().length < 2) errors.firstname = "Minimum 2 caractères";
  if (!identity.lastname.trim())          errors.lastname = "Le nom est requis";
  else if (identity.lastname.trim().length < 2)  errors.lastname = "Minimum 2 caractères";
  if (!identity.dateofbirth)              errors.dateofbirth = "La date de naissance est requise";
  else {
    const dob = new Date(identity.dateofbirth);
    const age = new Date().getFullYear() - dob.getFullYear();
    if (age < 18)  errors.dateofbirth = "Vous devez avoir au moins 18 ans";
    if (age > 100) errors.dateofbirth = "Date invalide";
  }
  return errors;
}

// ─── Camera button config ─────────────────────────────────────────────────
const CAM_BUTTONS = [
  { action: "rotateLeft",  icon: "↺", label: "Rotation gauche",   title: "Tourner à gauche" },
  { action: "rotateRight", icon: "↻", label: "Rotation droite",   title: "Tourner à droite" },
  { action: "zoomIn",      icon: "⊕", label: "Zoom +",            title: "Zoom avant"       },
  { action: "zoomOut",     icon: "⊖", label: "Zoom -",            title: "Zoom arrière"     },
  { action: "focusHead",   icon: "◯", label: "Focus tête",        title: "Focus visage"     },
  { action: "focusBody",   icon: "▭", label: "Focus corps",       title: "Focus corps"      },
  { action: "focusFull",   icon: "▬", label: "Vue complète",      title: "Vue entière"      },
  { action: "resetCam",    icon: "⌖", label: "Réinitialiser",     title: "Réinitialiser caméra" },
];

export default function Creator() {
  const [visible,     setVisible]     = useState(false);
  const [stepIndex,   setStepIndex]   = useState(0);
  const [errors,      setErrors]      = useState<Record<string, string>>({});
  const [successMsg,  setSuccessMsg]  = useState("");
  const [serverError, setServerError] = useState("");

  const [identity, setIdentity] = useState<IdentityData>({
    identifier: "", unique_id: "", firstname: "", lastname: "",
    dateofbirth: "", gender: "mp_m_freemode_01",
  });

  const [headBlend,    setHeadBlend]    = useState<HeadBlend>(DEFAULT_HEAD_BLEND);
  const [faceFeatures, setFaceFeatures] = useState<FaceFeaturesType>(DEFAULT_FACE_FEATURES);
  const [headOverlays, setHeadOverlays] = useState<HeadOverlaysType>(DEFAULT_HEAD_OVERLAYS);
  const [hair,         setHair]         = useState({ style: 0, color: 0, highlight: 0 });
  const [components,   setComponents]   = useState<ClothingComponents>(DEFAULT_COMPONENTS);
  const [props,        setProps]        = useState<Props>(DEFAULT_PROPS);
  const [tattoos,      setTattoos]      = useState<Tattoo[]>([]);

  const currentStep = STEPS[stepIndex];

  const getResourceName = useCallback((): string => {
    if ((window as any).GetParentResourceName) return (window as any).GetParentResourceName();
    return "kt_character";
  }, []);

  const nuiFetch = useCallback(async (endpoint: string, body: object): Promise<boolean> => {
    try {
      const res = await fetch(`https://${getResourceName()}/${endpoint}`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      return res.ok;
    } catch { return false; }
  }, [getResourceName]);

  const buildPayload = useCallback(() => ({
    ...identity, headBlend, faceFeatures, headOverlays, hair, components, props, tattoos,
  }), [identity, headBlend, faceFeatures, headOverlays, hair, components, props, tattoos]);

  const sendPreview = useCallback(async (payload: object) => {
    setServerError("");
    await nuiFetch("update", payload);
  }, [nuiFetch]);

  // ─── Changer d'étape et sync caméra ──────────────────────────────────
  const goToStep = useCallback((index: number) => {
    const step = STEPS[index];
    if (!step) return;
    setStepIndex(index);
    nuiFetch("tabChange", { tab: step.tab });
  }, [nuiFetch]);

  const nextStep = () => {
    if (stepIndex === 0) {
      const fieldErrors = validateIdentity(identity);
      if (Object.keys(fieldErrors).length > 0) { setErrors(fieldErrors); return; }
      setErrors({});
    }
    if (stepIndex < STEPS.length - 1) goToStep(stepIndex + 1);
  };

  const prevStep = () => {
    if (stepIndex > 0) goToStep(stepIndex - 1);
  };

  // ─── Commande caméra ──────────────────────────────────────────────────
  const camControl = useCallback((action: string) => {
    nuiFetch("cameraControl", { action });
  }, [nuiFetch]);

  // ─── Messages NUI entrants ────────────────────────────────────────────
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg?.type) return;
      switch (msg.type) {
        case "open":
          setVisible(true); setStepIndex(0);
          setErrors({}); setServerError(""); setSuccessMsg("");
          break;
        case "close":   setVisible(false); break;
        case "setIdentifier":
          setIdentity((p) => ({
            ...p,
            identifier: msg.identifier ?? p.identifier,
            unique_id:  msg.unique_id  ?? p.unique_id,
          })); break;
        case "error":   setServerError(msg.message ?? "Erreur inconnue"); break;
      }
    };
    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  }, []);

  if (!visible) return null;

  // ─── Handlers ─────────────────────────────────────────────────────────
  const updateIdentity = (key: keyof IdentityData, value: string) => {
    setIdentity((prev) => {
      const updated = { ...prev, [key]: value };
      if (key === "gender") sendPreview({ gender: value });
      return updated;
    });
    if (errors[key]) setErrors((e) => { const n = { ...e }; delete n[key]; return n; });
  };

  const updateHeadBlend    = (d: HeadBlend)          => { setHeadBlend(d);    sendPreview({ headBlend: d }); };
  const updateFaceFeatures = (d: FaceFeaturesType)   => { setFaceFeatures(d); sendPreview({ faceFeatures: d }); };
  const updateHeadOverlays = (d: HeadOverlaysType)   => { setHeadOverlays(d); sendPreview({ headOverlays: d }); };
  const updateComponents   = (d: ClothingComponents) => { setComponents(d);   sendPreview({ components: d }); };
  const updatePropsData    = (d: Props)               => { setProps(d);        sendPreview({ props: d }); };
  const updateTattoos      = (d: Tattoo[])            => { setTattoos(d);      sendPreview({ tattoos: d }); };

  const updateHair = (patch: Partial<typeof hair>) => {
    setHair((prev) => {
      const updated = { ...prev, ...patch };
      sendPreview({ hair: updated });
      return updated;
    });
  };

  const handleSubmit = async () => {
    const fieldErrors = validateIdentity(identity);
    if (Object.keys(fieldErrors).length > 0) {
      setErrors(fieldErrors); goToStep(0); return;
    }
    setErrors({});
    const ok = await nuiFetch("createCharacter", buildPayload());
    if (ok) {
      setSuccessMsg("✓ Personnage créé avec succès!");
      setTimeout(() => setSuccessMsg(""), 3000);
    } else {
      setServerError("Erreur lors de la création du personnage");
    }
  };

  const getAge = () => {
    if (!identity.dateofbirth) return null;
    const age = new Date().getFullYear() - new Date(identity.dateofbirth).getFullYear();
    return isNaN(age) ? null : age;
  };

  const isLastStep = stepIndex === STEPS.length - 1;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RENDER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  return (
    <>
      {/* ── Boutons caméra flottants (droite) ──────────────────────── */}
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

      {/* ── Panneau principal ──────────────────────────────────────── */}
      <div className={styles.container}>

        {/* Step progress bar */}
        <div className={styles.stepBar}>
          {STEPS.map((s, i) => (
            <button
              key={s.id}
              className={`${styles.stepDot} ${i === stepIndex ? styles.stepActive : ""} ${i < stepIndex ? styles.stepDone : ""}`}
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
        </div>

        {/* Messages */}
        {serverError && <div className={styles.error}>{serverError}</div>}
        {successMsg  && <div className={styles.success}>{successMsg}</div>}

        {/* ── Step content ──────────────────────────────────────────── */}
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
                    className={`${styles.genderBtn} ${identity.gender === "mp_m_freemode_01" ? styles.genderActive : ""}`}
                    onClick={() => updateIdentity("gender", "mp_m_freemode_01")}
                  >
                    <span className={styles.genderIcon}>♂</span>
                    <span className={styles.genderLabel}>Masculin</span>
                    <span className={styles.genderSub}>mp_m</span>
                  </button>
                  <button
                    className={`${styles.genderBtn} ${identity.gender === "mp_f_freemode_01" ? styles.genderActive : ""}`}
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
                onChangeProps={updatePropsData}
              />
            </Category>
          )}

          {currentStep.id === "tattoos" && (
            <Category title="Tatouages" icon="💉">
              <Tattoos applied={tattoos} onChange={updateTattoos} />
            </Category>
          )}
        </div>

        {/* ── Navigation ───────────────────────────────────────────── */}
        <div className={styles.navRow}>
          <button
            className={styles.navBtn}
            onClick={prevStep}
            disabled={stepIndex === 0}
          >
            ← Retour
          </button>

          {isLastStep ? (
            <button className={styles.submitBtn} onClick={handleSubmit}>
              ✓ Créer le personnage
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