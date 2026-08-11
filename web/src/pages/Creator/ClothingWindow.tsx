// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ClothingWindow — fenêtre 2/2, indépendante
// Aperçu + Catégories/Vêtements/Accessoires (AssetPickerPage) + Caméra
// → bouton Créer le personnage
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import styles from "./ClothingWindow.module.scss";
import AssetPickerPage from "../AssetPickerPage/AssetPickerPage";
import type { ClothingComponents, Props, HeadOverlays } from "../../types/appearance.types";

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

interface ClothingWindowProps {
  gender: "mp_m_freemode_01" | "mp_f_freemode_01";
  submitting: boolean;
  serverError: string;
  camControl: (action: string) => void;
  onPreview: (components: ClothingComponents, props: Props, overlays: HeadOverlays) => void;
  onClearAll: () => void;
  onSubmit: () => void;
  onClose: () => void;
}

export default function ClothingWindow({
  gender, submitting, serverError,
  camControl, onPreview, onClearAll, onSubmit, onClose,
}: ClothingWindowProps) {
  return (
    <>
      {/* ── Panneau caméra ── */}
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

      {/* ── Fenêtre principale ── */}
      <div className={styles.container}>

        {/* ── Header ── */}
        <div className={styles.header}>
          <h2 className={styles.title}>
            <span>👔</span>
            Tenue
          </h2>
          <button
            type="button"
            className={styles.closeBtn}
            onClick={onClose}
            disabled={submitting}
            aria-label="Fermer"
          >
            ×
          </button>
        </div>

        {/* ── Erreur serveur ── */}
        {serverError && <div className={styles.error}>{serverError}</div>}

        {/* ── Body : aperçu + catégories/vêtements/accessoires ── */}
        <div className={styles.body}>
          <AssetPickerPage
            gender={gender}
            onPreview={onPreview}
            onValidate={onPreview}
            onClearAll={onClearAll}
          />
        </div>

        {/* ── Footer ── */}
        <div className={styles.footer}>
          <button
            className={styles.submitBtn}
            onClick={onSubmit}
            disabled={submitting}
          >
            {submitting ? "⏳ Création..." : "✓ Créer le personnage"}
          </button>
        </div>

      </div>
    </>
  );
}
