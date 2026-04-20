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

const CREATOR_TABS = [
  { id: "identity", label: "Identité",  icon: "👤" },
  { id: "parents",  label: "Parents",   icon: "🧬" },
  { id: "features", label: "Traits",    icon: "◉"  },
  { id: "overlays", label: "Overlays",  icon: "🎨" },
  { id: "hair",     label: "Cheveux",   icon: "✦"  },
  { id: "clothing", label: "Tenues",    icon: "👔" },
  { id: "tattoos",  label: "Tatouages", icon: "💉" },
];

export default function Creator() {
  // ─── Visibilité (contrôlée par NUI message "open" / "close") ──────────
  const [visible, setVisible] = useState(false);

  // ─── État UI ──────────────────────────────────────────────────────────
  const [tab,         setTabState] = useState("identity");
  const [errors,      setErrors]   = useState<Record<string, string>>({});
  const [successMsg,  setSuccessMsg]  = useState("");
  const [serverError, setServerError] = useState("");

  // ─── Identité ─────────────────────────────────────────────────────────
  const [identity, setIdentity] = useState<IdentityData>({
    identifier:  "",
    unique_id:   "",
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

  const sendPreview = useCallback(async (payload: object) => {
    setServerError("");
    await nuiFetch("update", payload);
  }, [nuiFetch]);

  const setTab = useCallback((newTab: string) => {
    setTabState(newTab);
    nuiFetch("tabChange", { tab: newTab });
  }, [nuiFetch]);

  // ─── Messages NUI entrants ────────────────────────────────────────────
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg || !msg.type) return;

      switch (msg.type) {
        case "open":
          setVisible(true);
          setTabState("identity");
          setErrors({});
          setServerError("");
          setSuccessMsg("");
          break;

        case "close":
          setVisible(false);
          break;

        case "setIdentifier":
          setIdentity((prev) => ({
            ...prev,
            identifier: msg.identifier ?? prev.identifier,
            unique_id:  msg.unique_id  ?? prev.unique_id,
          }));
          break;

        case "error":
          setServerError(msg.message ?? "Erreur inconnue");
          break;
      }
    };

    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  }, []);

  // ─── Ne rien rendre si le creator est fermé ───────────────────────────
  if (!visible) return null;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HANDLERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  const updateIdentity = (key: keyof IdentityData, value: string) => {
    setIdentity((prev) => {
      const updated = { ...prev, [key]: value };
      if (key === "gender") sendPreview({ gender: value });
      return updated;
    });
    if (errors[key]) setErrors((e) => { const n = { ...e }; delete n[key]; return n; });
  };

  const updateHeadBlend    = (data: HeadBlend)          => { setHeadBlend(data);    sendPreview({ headBlend: data }); };
  const updateFaceFeatures = (data: FaceFeaturesType)   => { setFaceFeatures(data); sendPreview({ faceFeatures: data }); };
  const updateHeadOverlays = (data: HeadOverlaysType)   => { setHeadOverlays(data); sendPreview({ headOverlays: data }); };
  const updateComponents   = (data: ClothingComponents) => { setComponents(data);   sendPreview({ components: data }); };
  const updateProps        = (data: Props)               => { setProps(data);        sendPreview({ props: data }); };
  const updateTattoos      = (data: Tattoo[])            => { setTattoos(data);      sendPreview({ tattoos: data }); };

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
  };

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

      {tab === "identity" && (
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

          <button className={styles.submitBtn} onClick={handleSubmit}>
            Créer le personnage →
          </button>
        </>
      )}

      {tab === "parents" && (
        <Category title="Mélange parental" icon="🧬">
          <Parents data={headBlend} onChange={updateHeadBlend} />
        </Category>
      )}

      {tab === "features" && (
        <Category title="Traits du visage" icon="◉">
          <FaceFeatures data={faceFeatures} onChange={updateFaceFeatures} />
        </Category>
      )}

      {tab === "overlays" && (
        <Category title="Overlays" icon="🎨">
          <HeadOverlays data={headOverlays} onChange={updateHeadOverlays} />
        </Category>
      )}

      {tab === "hair" && (
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

      {tab === "clothing" && (
        <Category title="Vêtements & Accessoires" icon="👔">
          <Clothing
            components={components} props={props}
            onChangeComponents={updateComponents}
            onChangeProps={updateProps}
          />
        </Category>
      )}

      {tab === "tattoos" && (
        <Category title="Tatouages" icon="💉">
          <Tattoos applied={tattoos} onChange={updateTattoos} />
        </Category>
      )}
    </div>
  );
}