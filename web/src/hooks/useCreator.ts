// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// useCreator.ts — Toute la logique du creator (NUI, état, submit, close)
// Creator.tsx ne fait que le rendu — il ne contient AUCUNE logique métier
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useState, useCallback, useEffect } from "react";
import {
  DEFAULT_HEAD_BLEND,
  DEFAULT_FACE_FEATURES,
  DEFAULT_HEAD_OVERLAYS,
  DEFAULT_COMPONENTS,
  DEFAULT_PROPS,
} from "../types/appearance.types";
import type {
  HeadBlend,
  FaceFeatures,
  HeadOverlays,
  ClothingComponents,
  Props,
  Tattoo,
} from "../types/appearance.types";

// ─── Types ────────────────────────────────────────────────────────────────
export interface IdentityData {
  identifier:  string;
  unique_id:   string;
  firstname:   string;
  lastname:    string;
  dateofbirth: string;
  gender: "mp_m_freemode_01" | "mp_f_freemode_01";
}

export const STEPS = [
  { id: "identity", label: "Identité",  icon: "👤", tab: "identity" },
  { id: "parents",  label: "Parents",   icon: "🧬", tab: "parents"  },
  { id: "features", label: "Traits",    icon: "◉",  tab: "features" },
  { id: "overlays", label: "Overlays",  icon: "🎨", tab: "overlays" },
  { id: "hair",     label: "Cheveux",   icon: "✦",  tab: "hair"     },
  { id: "clothing", label: "Tenue",     icon: "👔", tab: "clothing" },
  { id: "tattoos",  label: "Tatouages", icon: "💉", tab: "tattoos"  },
] as const;

export type StepId = typeof STEPS[number]["id"];

// ─── Validation identité ──────────────────────────────────────────────────
function validateIdentity(identity: IdentityData): Record<string, string> {
  const errors: Record<string, string> = {};

  if (!identity.firstname.trim())
    errors.firstname = "Le prénom est requis";
  else if (identity.firstname.trim().length < 2)
    errors.firstname = "Minimum 2 caractères";

  if (!identity.lastname.trim())
    errors.lastname = "Le nom est requis";
  else if (identity.lastname.trim().length < 2)
    errors.lastname = "Minimum 2 caractères";

  if (!identity.dateofbirth) {
    errors.dateofbirth = "La date de naissance est requise";
  } else {
    const age = new Date().getFullYear() - new Date(identity.dateofbirth).getFullYear();
    if (age < 18)  errors.dateofbirth = "Vous devez avoir au moins 18 ans";
    if (age > 100) errors.dateofbirth = "Date invalide";
  }

  return errors;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HOOK PRINCIPAL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export function useCreator() {
  // ── Visibilité / étapes ────────────────────────────────────────────────
  const [visible,     setVisible]     = useState(false);
  const [stepIndex,   setStepIndex]   = useState(0);
  const [errors,      setErrors]      = useState<Record<string, string>>({});
  const [serverError, setServerError] = useState("");
  const [submitting,  setSubmitting]  = useState(false);

  // ── Données apparence ──────────────────────────────────────────────────
  const [identity, setIdentity] = useState<IdentityData>({
    identifier: "", unique_id: "", firstname: "", lastname: "",
    dateofbirth: "", gender: "mp_m_freemode_01",
  });
  const [headBlend,    setHeadBlend]    = useState<HeadBlend>(DEFAULT_HEAD_BLEND);
  const [faceFeatures, setFaceFeatures] = useState<FaceFeatures>(DEFAULT_FACE_FEATURES);
  const [headOverlays, setHeadOverlays] = useState<HeadOverlays>(DEFAULT_HEAD_OVERLAYS);
  const [hair,         setHair]         = useState({ style: 0, color: 0, highlight: 0 });
  const [components,   setComponents]   = useState<ClothingComponents>(DEFAULT_COMPONENTS);
  const [props,        setProps]        = useState<Props>(DEFAULT_PROPS);
  const [tattoos,      setTattoos]      = useState<Tattoo[]>([]);

  // ── NUI helpers ────────────────────────────────────────────────────────
  const getResourceName = useCallback((): string => {
    if ((window as any).GetParentResourceName) return (window as any).GetParentResourceName();
    return "kt_character";
  }, []);

  const nuiFetch = useCallback(async (endpoint: string, body: object): Promise<boolean> => {
    try {
      const res = await fetch(`https://${getResourceName()}/${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      return res.ok;
    } catch {
      return false;
    }
  }, [getResourceName]);

  // ── Payload complet ────────────────────────────────────────────────────
  const buildPayload = useCallback(() => ({
    ...identity, headBlend, faceFeatures, headOverlays, hair, components, props, tattoos,
  }), [identity, headBlend, faceFeatures, headOverlays, hair, components, props, tattoos]);

  // ── Fermeture UI ───────────────────────────────────────────────────────
  // Appelable même si submitting (on reset avant d'appeler)
  const closeUI = useCallback(async () => {
    setSubmitting(false);
    setServerError("");
    await nuiFetch("close", {});
    setVisible(false);
  }, [nuiFetch]);

  // ── Navigation étapes ──────────────────────────────────────────────────
  const goToStep = useCallback((index: number) => {
    const step = STEPS[index];
    if (!step) return;
    setStepIndex(index);
    nuiFetch("tabChange", { tab: step.tab });
  }, [nuiFetch]);

  const nextStep = useCallback(() => {
    if (stepIndex === 0) {
      const fieldErrors = validateIdentity(identity);
      if (Object.keys(fieldErrors).length > 0) {
        setErrors(fieldErrors);
        return;
      }
      setErrors({});
    }
    if (stepIndex < STEPS.length - 1) goToStep(stepIndex + 1);
  }, [stepIndex, identity, goToStep]);

  const prevStep = useCallback(() => {
    if (stepIndex > 0) goToStep(stepIndex - 1);
  }, [stepIndex, goToStep]);

  // ── Soumission personnage ──────────────────────────────────────────────
  const handleSubmit = useCallback(async () => {
    const fieldErrors = validateIdentity(identity);
    if (Object.keys(fieldErrors).length > 0) {
      setErrors(fieldErrors);
      goToStep(0);
      return;
    }
    setErrors({});
    setSubmitting(true);

    const created = await nuiFetch("createCharacter", buildPayload());
    if (!created) {
      setServerError("La création du personnage a échoué.");
      setSubmitting(false);
      return;
    }

    // ✅ reset submitting AVANT closeUI (sinon handleClose bailait)
    setSubmitting(false);
    await closeUI();
  }, [identity, buildPayload, nuiFetch, goToStep, closeUI]);

  // ── Aperçu temps réel ──────────────────────────────────────────────────
  const sendPreview = useCallback((patch: object) => {
    nuiFetch("update", patch);
  }, [nuiFetch]);

  // ── Contrôle caméra ───────────────────────────────────────────────────
  const camControl = useCallback((action: string) => {
    nuiFetch("cameraControl", { action });
  }, [nuiFetch]);

  // ── Mise à jour identity ───────────────────────────────────────────────
  const updateIdentity = useCallback((key: keyof IdentityData, value: string) => {
    setIdentity((prev) => {
      const updated = { ...prev, [key]: value };
      if (key === "gender") sendPreview({ gender: value });
      return updated;
    });
    setErrors((e) => { const n = { ...e }; delete n[key]; return n; });
  }, [sendPreview]);

  // ── Mise à jour apparence ─────────────────────────────────────────────
  const updateHeadBlend = useCallback((d: HeadBlend) => {
    setHeadBlend(d);
    sendPreview({ headBlend: d });
  }, [sendPreview]);

  const updateFaceFeatures = useCallback((d: FaceFeatures) => {
    setFaceFeatures(d);
    sendPreview({ faceFeatures: d });
  }, [sendPreview]);

  const updateHeadOverlays = useCallback((d: HeadOverlays) => {
    setHeadOverlays(d);
    sendPreview({ headOverlays: d });
  }, [sendPreview]);

  const updateHair = useCallback((patch: Partial<typeof hair>) => {
    setHair((prev) => {
      const updated = { ...prev, ...patch };
      sendPreview({ hair: updated });
      return updated;
    });
  }, [sendPreview]);

  const updateComponents = useCallback((d: ClothingComponents) => {
    setComponents(d);
    sendPreview({ components: d });
  }, [sendPreview]);

  const updateProps = useCallback((d: Props) => {
    setProps(d);
    sendPreview({ props: d });
  }, [sendPreview]);

  const updateTattoos = useCallback((d: Tattoo[]) => {
    setTattoos(d);
    sendPreview({ tattoos: d });
  }, [sendPreview]);

  // ── Écoute messages NUI (Lua → React) ────────────────────────────────
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg?.type) return;

      switch (msg.type) {
        case "open":
          setVisible(true);
          setStepIndex(0);
          setErrors({});
          setServerError("");
          setSubmitting(false);
          // Si skinData fourni (mode /skin), pré-remplir les données
          if (msg.skinData) {
            const s = msg.skinData;
            if (s.headBlend)    setHeadBlend(s.headBlend);
            if (s.faceFeatures) setFaceFeatures(s.faceFeatures);
            if (s.headOverlays) setHeadOverlays(s.headOverlays);
            if (s.hair)         setHair(s.hair);
            if (s.components)   setComponents(s.components);
            if (s.props)        setProps(s.props);
            if (s.tattoos)      setTattoos(s.tattoos);
          }
          break;

        case "close":
          setVisible(false);
          setSubmitting(false);
          setServerError("");
          setErrors({});
          break;

        case "setIdentifier":
          setIdentity((p) => ({
            ...p,
            identifier: msg.identifier ?? p.identifier,
            unique_id:  msg.unique_id  ?? p.unique_id,
          }));
          break;

        case "error":
          setServerError(msg.message ?? "Erreur inconnue");
          setSubmitting(false);
          break;
      }
    };

    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  }, []);

  // ── Fermeture clavier (Echap) ─────────────────────────────────────────
  useEffect(() => {
    if (!visible) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key !== "Escape") return;
      e.preventDefault();
      void closeUI();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [visible, closeUI]);

  // ── Utilitaires exposés ────────────────────────────────────────────────
  const getAge = useCallback((): number | null => {
    if (!identity.dateofbirth) return null;
    const age = new Date().getFullYear() - new Date(identity.dateofbirth).getFullYear();
    return isNaN(age) ? null : age;
  }, [identity.dateofbirth]);

  return {
    // État UI
    visible,
    stepIndex,
    errors,
    serverError,
    submitting,
    isLastStep: stepIndex === STEPS.length - 1,
    currentStep: STEPS[stepIndex],

    // Données
    identity,
    headBlend,
    faceFeatures,
    headOverlays,
    hair,
    components,
    props,
    tattoos,

    // Actions
    closeUI,
    goToStep,
    nextStep,
    prevStep,
    handleSubmit,
    camControl,
    getAge,

    // Updaters
    updateIdentity,
    updateHeadBlend,
    updateFaceFeatures,
    updateHeadOverlays,
    updateHair,
    updateComponents,
    updateProps,
    updateTattoos,
  };
}