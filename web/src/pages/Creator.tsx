import styles from "./Creator.module.scss";
import { useState, useCallback, useEffect } from "react";

// ─── Composants UI ────────────────────────────────────────────────────────
import Tabs        from "../components/Tabs/Tabs";
import Slider      from "../components/Slider/Slider";
import Category    from "../components/Category/Category";
import ColorPicker from "../components/ColorPicker/ColorPicker";
import Field       from "../components/Field/Field";
import Parents     from "../components/Parents/Parents";
import FaceFeatures from "../components/FaceFeatures/FaceFeatures";
import HeadOverlays from "../components/HeadOverlays/HeadOverlays";
import Clothing    from "../components/Clothing/Clothing";
import Tattoos     from "../components/Tattoos/Tattoos";

// ─── Types ────────────────────────────────────────────────────────────────
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TYPES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

interface IdentityData {
  identifier:  string;
  unique_id:   string;
  firstname:   string;
  lastname:    string;
  dateofbirth: string;
  gender: "mp_m_freemode_01" | "mp_f_freemode_01";
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VALIDATION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

  if (!identity.dateofbirth)
    errors.dateofbirth = "La date de naissance est requise";
  else {
    const dob = new Date(identity.dateofbirth);
    const age = new Date().getFullYear() - dob.getFullYear();
    if (age < 18) errors.dateofbirth = "Vous devez avoir au moins 18 ans";
    if (age > 100) errors.dateofbirth = "Date invalide";
  }

  return errors;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ONGLETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const CREATOR_TABS = [
  { id: "identity", label: "Identité",  icon: "👤" },
  { id: "parents",  label: "Parents",   icon: "🧬" },
  { id: "features", label: "Traits",    icon: "◉"  },
  { id: "overlays", label: "Overlays",  icon: "🎨" },
  { id: "hair",     label: "Cheveux",   icon: "✦"  },
  { id: "clothing", label: "Tenues",    icon: "👔" },
  { id: "tattoos",  label: "Tatouages", icon: "💉" },
];

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPOSANT PRINCIPAL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export default function Creator() {
  // ─── État UI ──────────────────────────────────────────────────────────
  const [tab,         setTabState] = useState("identity");
  const [errors,      setErrors]   = useState<Record<string, string>>({});
  const [successMsg,  setSuccessMsg]  = useState("");
  const [serverError, setServerError] = useState("");

  // ─── Identité ─────────────────────────────────────────────────────────
  const [identity, setIdentity] = useState<IdentityData>({
    identifier:  (window as any).__kt_identifier ?? "",
    unique_id:   (window as any).__kt_unique_id  ?? "",
    firstname:   "",
    lastname:    "",
    dateofbirth: "",
    gender:      "mp_m_freemode_01",
  });

  // ─── Apparence ────────────────────────────────────────────────────────
  const [headBlend,    setHeadBlend]    = useState<HeadBlend>(DEFAULT_HEAD_BLEND);
  const [faceFeatures, setFaceFeatures] = useState<FaceFeaturesType>(DEFAULT_FACE_FEATURES);
  const [headOverlays, setHeadOverlays] = useState<HeadOverlaysType>(DEFAULT_HEAD_OVERLAYS);
  const [hair,         setHair]         = useState({ style: 0, color: 0, highlight: 0 });
  const [components,   setComponents]   = useState<ClothingComponents>(DEFAULT_COMPONENTS);
  const [props,        setProps]        = useState<Props>(DEFAULT_PROPS);
  const [tattoos,      setTattoos]      = useState<Tattoo[]>([]);

  // ─── Helpers NUI ──────────────────────────────────────────────────────
  const getResourceName = useCallback((): string => {
    if ((window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return "kt_character";
  }, []);

  const nuiFetch = useCallback(
    async (endpoint: string, body: object): Promise<boolean> => {
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
    },
    [getResourceName]
  );

  // ─── Construire le payload complet ────────────────────────────────────
  const buildPayload = useCallback(() => ({
    ...identity,
    headBlend,
    faceFeatures,
    headOverlays,
    hair,
    components,
    props,
    tattoos,
  }), [identity, headBlend, faceFeatures, headOverlays, hair, components, props, tattoos]);

  // ─── Envoyer le preview au client Lua (debounced implicitement par React) ─
  const sendPreview = useCallback(async (payload: object) => {
    setServerError("");
    const ok = await nuiFetch("update", payload);
    if (!ok) setServerError("Erreur de connexion");
  }, [nuiFetch]);

  // ─── Changement d'onglet → focus caméra ──────────────────────────────
  const setTab = useCallback((newTab: string) => {
    setTabState(newTab);
    nuiFetch("tabChange", { tab: newTab });
  }, [nuiFetch]);

  // ─── Messages NUI entrants (identifier, erreurs) ──────────────────────
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg || !msg.type) return;

      if (msg.type === "setIdentifier") {
        setIdentity((prev) => ({
          ...prev,
          identifier: msg.identifier ?? prev.identifier,
          unique_id:  msg.unique_id  ?? prev.unique_id,
        }));
      } else if (msg.type === "error") {
        setServerError(msg.message ?? "Erreur inconnue");
      } else if (msg.type === "close") {
        // Le serveur peut forcer la fermeture
      }
    };

    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  }, []);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HANDLERS DE MISE À JOUR + PREVIEW
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  const updateIdentity = useCallback((key: keyof IdentityData, value: string) => {
    setIdentity((prev) => {
      const updated = { ...prev, [key]: value };
      // Le genre change le modèle : preview immédiat
      if (key === "gender") {
        sendPreview({ gender: value });
      }
      return updated;
    });
    if (errors[key]) {
      setErrors((e) => { const n = { ...e }; delete n[key]; return n; });
    }
  }, [errors, sendPreview]);

  const updateHeadBlend = useCallback((data: HeadBlend) => {
    setHeadBlend(data);
    sendPreview({ headBlend: data });
  }, [sendPreview]);

  const updateFaceFeatures = useCallback((data: FaceFeaturesType) => {
    setFaceFeatures(data);
    sendPreview({ faceFeatures: data });
  }, [sendPreview]);

  const updateHeadOverlays = useCallback((data: HeadOverlaysType) => {
    setHeadOverlays(data);
    sendPreview({ headOverlays: data });
  }, [sendPreview]);

  const updateHair = useCallback((patch: Partial<typeof hair>) => {
    setHair((prev) => {
      const updated = { ...prev, ...patch };
      sendPreview({ hair: updated });
      return updated;
    });
  }, [sendPreview]);

  const updateComponents = useCallback((data: ClothingComponents) => {
    setComponents(data);
    sendPreview({ components: data });
  }, [sendPreview]);

  const updateProps = useCallback((data: Props) => {
    setProps(data);
    sendPreview({ props: data });
  }, [sendPreview]);

  const updateTattoos = useCallback((data: Tattoo[]) => {
    setTattoos(data);
    sendPreview({ tattoos: data });
  }, [sendPreview]);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SOUMISSION FINALE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  const handleSubmit = useCallback(async () => {
    const fieldErrors = validateIdentity(identity);
    if (Object.keys(fieldErrors).length > 0) {
      setErrors(fieldErrors);
      setTab("identity");
      return;
    }

    setErrors({});
    const ok = await nuiFetch("createCharacter", buildPayload());
    if (ok) {
      setSuccessMsg("✓ Personnage créé avec succès!");
      setTimeout(() => setSuccessMsg(""), 3000);
    } else {
      setServerError("Erreur lors de la création du personnage");
    }
  }, [identity, buildPayload, nuiFetch, setTab]);

  // ─── Âge calculé ─────────────────────────────────────────────────────
  const getAge = () => {
    if (!identity.dateofbirth) return null;
    const age = new Date().getFullYear() - new Date(identity.dateofbirth).getFullYear();
    return isNaN(age) ? null : age;
  };

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RENDER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  return (
    <div className={styles.container}>
      <Tabs tab={tab} setTab={setTab} tabs={CREATOR_TABS} />

      {serverError && <div className={styles.error}>{serverError}</div>}
      {successMsg  && <div className={styles.success}>{successMsg}</div>}

      {/* ─── IDENTITÉ ──────────────────────────────────────────────────── */}
      {tab === "identity" && (
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
              label={`Date de naissance${getAge() ? ` (${getAge()} ans)` : ""}`}
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

          <button className={styles.submitBtn} onClick={handleSubmit}>
            Créer le personnage →
          </button>
        </>
      )}

      {/* ─── PARENTS (Head Blend) ─────────────────────────────────────── */}
      {tab === "parents" && (
        <Category title="Mélange parental" icon="🧬">
          <Parents data={headBlend} onChange={updateHeadBlend} />
        </Category>
      )}

      {/* ─── TRAITS DU VISAGE ─────────────────────────────────────────── */}
      {tab === "features" && (
        <Category title="Traits du visage" icon="◉">
          <FaceFeatures data={faceFeatures} onChange={updateFaceFeatures} />
        </Category>
      )}

      {/* ─── OVERLAYS ─────────────────────────────────────────────────── */}
      {tab === "overlays" && (
        <Category title="Overlays" icon="🎨">
          <HeadOverlays data={headOverlays} onChange={updateHeadOverlays} />
        </Category>
      )}

      {/* ─── CHEVEUX ──────────────────────────────────────────────────── */}
      {tab === "hair" && (
        <>
          <Category title="Coiffure" icon="✦">
            <Slider
              label="Style"
              min={0} max={75}
              value={hair.style}
              onChange={(v) => updateHair({ style: v })}
            />
          </Category>
          <Category title="Couleur principale" icon="🎨">
            <ColorPicker
              label="Couleur"
              value={hair.color}
              onChange={(v) => updateHair({ color: v })}
            />
          </Category>
          <Category title="Reflet / Highlight" icon="✨">
            <ColorPicker
              label="Reflet"
              value={hair.highlight}
              onChange={(v) => updateHair({ highlight: v })}
            />
          </Category>
        </>
      )}

      {/* ─── TENUES ───────────────────────────────────────────────────── */}
      {tab === "clothing" && (
        <Category title="Vêtements & Accessoires" icon="👔">
          <Clothing
            components={components}
            props={props}
            onChangeComponents={updateComponents}
            onChangeProps={updateProps}
          />
        </Category>
      )}

      {/* ─── TATOUAGES ────────────────────────────────────────────────── */}
      {tab === "tattoos" && (
        <Category title="Tatouages" icon="💉">
          <Tattoos applied={tattoos} onChange={updateTattoos} />
        </Category>
      )}
    </div>
  );
}