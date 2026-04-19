import styles from "./Creator.module.sass";
import { useState, useCallback } from "react";
import Tabs from "../components/Tabs/Tabs";
import Slider from "../components/Slider/Slider";
import Category from "../components/Category/Category";
import ColorPicker from "../components/ColorPicker/ColorPicker";
import Field from "../components/Field/Field";

// ─── Types ────────────────────────────────────────────────────────────────────

interface IdentityData {
  identifier: string;       // license:xxxx (readonly, depuis FiveM)
  unique_id: string;        // UUID multichar (readonly, généré)
  firstname: string;
  lastname: string;
  dateofbirth: string;      // YYYY-MM-DD
  gender: "mp_m_freemode_01" | "mp_f_freemode_01";
}

interface AppearanceData {
  hair: number;
  beard: number;
  hairColor: number;
}

interface CreatorData extends IdentityData, AppearanceData {}

// ─── Validation ───────────────────────────────────────────────────────────────

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
    const now = new Date();
    const age = now.getFullYear() - dob.getFullYear();
    if (age < 18) errors.dateofbirth = "Vous devez avoir au moins 18 ans";
    if (age > 100) errors.dateofbirth = "Date invalide";
  }

  return errors;
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

const CREATOR_TABS = [
  { id: "identity", label: "Identité", icon: "◎" },
  { id: "face",     label: "Visage",   icon: "◉" },
  { id: "hair",     label: "Cheveux",  icon: "✦" },
];

// ─── Component ────────────────────────────────────────────────────────────────

export default function Creator() {
  const [tab, setTab] = useState<string>("identity");
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [successMsg, setSuccessMsg] = useState("");
  const [serverError, setServerError] = useState("");

  const [data, setData] = useState<CreatorData>({
    // Identity — identifier & unique_id sont injectés par FiveM via NUI message
    identifier: (window as any).__kt_identifier ?? "",
    unique_id:  (window as any).__kt_unique_id  ?? "",
    firstname:  "",
    lastname:   "",
    dateofbirth: "",
    gender: "mp_m_freemode_01",
    // Appearance
    hair: 0,
    beard: 0,
    hairColor: 0,
  });

  // ─── Resource name ──────────────────────────────────────────────────────────
  const getResourceName = useCallback((): string => {
    if (typeof window !== "undefined" && (window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return "kt_character";
  }, []);

  // ─── NUI fetch helper ───────────────────────────────────────────────────────
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

  // ─── Update appearance field ─────────────────────────────────────────────
  const updateAppearance = useCallback(
    async (key: keyof AppearanceData, value: number) => {
      const updated = { ...data, [key]: value };
      setData(updated);
      setServerError("");
      const ok = await nuiFetch("update", updated);
      if (!ok) setServerError("Erreur de connexion au serveur");
    },
    [data, nuiFetch]
  );

  // ─── Update identity field ───────────────────────────────────────────────
  const updateIdentity = useCallback(
    (key: keyof IdentityData, value: string) => {
      setData((prev) => ({ ...prev, [key]: value }));
      // Clear field error on change
      if (errors[key]) setErrors((e) => { const n = { ...e }; delete n[key]; return n; });
    },
    [errors]
  );

  // ─── Submit character ────────────────────────────────────────────────────
  const handleSubmit = useCallback(async () => {
    const fieldErrors = validateIdentity(data);
    if (Object.keys(fieldErrors).length > 0) {
      setErrors(fieldErrors);
      setTab("identity");
      return;
    }

    setErrors({});
    const ok = await nuiFetch("createCharacter", data);
    if (ok) {
      setSuccessMsg("✓ Personnage créé !");
      setTimeout(() => setSuccessMsg(""), 3000);
    } else {
      setServerError("Erreur lors de la création du personnage");
    }
  }, [data, nuiFetch]);

  // ─── Age display ─────────────────────────────────────────────────────────
  const getAge = () => {
    if (!data.dateofbirth) return null;
    const dob = new Date(data.dateofbirth);
    const age = new Date().getFullYear() - dob.getFullYear();
    return isNaN(age) ? null : age;
  };

  // ─── Render ──────────────────────────────────────────────────────────────
  return (
    <div className={styles.container}>
      <Tabs tab={tab} setTab={setTab} tabs={CREATOR_TABS} />

      {serverError && <div className={styles.error}>{serverError}</div>}
      {successMsg  && <div className={styles.success}>{successMsg}</div>}

      {/* ── IDENTITÉ ──────────────────────────────────────────────────── */}
      {tab === "identity" && (
        <>
          {/* Données FiveM (readonly) */}
          <Category title="Données FiveM" icon="🔒">
            <Field
              label="Identifier"
              type="readonly"
              value={data.identifier || "En attente…"}
              hint="Identifiant FiveM (license:xxxx)"
            />
            <Field
              label="Unique ID"
              type="readonly"
              value={data.unique_id || "En attente…"}
              hint="Identifiant unique du personnage"
            />
          </Category>

          {/* État civil */}
          <Category title="État civil" icon="👤">
            <Field
              label="Prénom"
              type="text"
              value={data.firstname}
              onChange={(v) => updateIdentity("firstname", v)}
              placeholder="ex: Jean"
              required
              error={errors.firstname}
            />
            <Field
              label="Nom"
              type="text"
              value={data.lastname}
              onChange={(v) => updateIdentity("lastname", v)}
              placeholder="ex: Dupont"
              required
              error={errors.lastname}
            />
            <Field
              label={`Date de naissance${getAge() ? ` (${getAge()} ans)` : ""}`}
              type="date"
              value={data.dateofbirth}
              onChange={(v) => updateIdentity("dateofbirth", v)}
              required
              error={errors.dateofbirth}
            />
          </Category>

          {/* Genre */}
          <Category title="Genre" icon="⚧">
            <div className={styles.genderRow}>
              <button
                className={`${styles.genderBtn} ${data.gender === "mp_m_freemode_01" ? styles.genderActive : ""}`}
                onClick={() => updateIdentity("gender", "mp_m_freemode_01")}
              >
                <span className={styles.genderIcon}>♂</span>
                <span className={styles.genderLabel}>Masculin</span>
                <span className={styles.genderSub}>mp_m_freemode_01</span>
              </button>
              <button
                className={`${styles.genderBtn} ${data.gender === "mp_f_freemode_01" ? styles.genderActive : ""}`}
                onClick={() => updateIdentity("gender", "mp_f_freemode_01")}
              >
                <span className={styles.genderIcon}>♀</span>
                <span className={styles.genderLabel}>Féminin</span>
                <span className={styles.genderSub}>mp_f_freemode_01</span>
              </button>
            </div>
          </Category>

          {/* Submit */}
          <button className={styles.submitBtn} onClick={handleSubmit}>
            Créer le personnage →
          </button>
        </>
      )}

      {/* ── VISAGE ────────────────────────────────────────────────────── */}
      {tab === "face" && (
        <Category title="Visage">
          <Slider
            label="Barbe"
            min={0}
            max={28}
            value={data.beard}
            onChange={(v) => updateAppearance("beard", v)}
          />
        </Category>
      )}

      {/* ── CHEVEUX ───────────────────────────────────────────────────── */}
      {tab === "hair" && (
        <Category title="Cheveux">
          <Slider
            label="Style"
            min={0}
            max={75}
            value={data.hair}
            onChange={(v) => updateAppearance("hair", v)}
          />
          <ColorPicker
            label="Couleur"
            value={data.hairColor}
            onChange={(v) => updateAppearance("hairColor", v)}
          />
        </Category>
      )}
    </div>
  );
}