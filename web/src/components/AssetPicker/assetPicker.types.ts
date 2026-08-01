// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ASSET PICKER — TYPES (v2 — texture + color support)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export type GenderModel = "mp_f_freemode_01" | "mp_m_freemode_01";

export interface AssetCategory {
  id: string;
  label: string;
  icon: string;
  count: number;

  // Résolution du type de donnée GTA
  componentId?: number | null; // SetPedComponentVariation
  propAnchor?: number | null;  // SetPedPropIndex
  overlayId?: number | null;   // SetPedHeadOverlay
  direct?: boolean;            // images à plat (ex: faces/0.png vs hair/0/0.png)

  // ── NOUVEAU ──────────────────────────────────────────────────────────
  /** Nombre de textures disponibles par drawable (défaut : 16) */
  textureCount?: number;
  /** Cet asset supporte-t-il une couleur GTA (cheveux, barbe, overlay) ? */
  hasColor?: boolean;
  /** Type de palette couleur : "hair" | "makeup" | "none" */
  colorType?: "hair" | "makeup" | "none";
  /** Nombre de textures max pour les props */
  propTextureCount?: number;
}

// ── Sélection enrichie ────────────────────────────────────────────────────
export interface ItemSelection {
  drawable: number;      // index du drawable / prop / overlay
  texture: number;       // texture index (0 par défaut)
  color?: number;        // firstColor (palette hair/makeup)
  highlight?: number;    // secondColor (reflet — cheveux surtout)
}

export interface PickerSelection {
  [catId: string]: ItemSelection;
}

export interface GenderSelections {
  mp_f_freemode_01: PickerSelection;
  mp_m_freemode_01: PickerSelection;
}

// ── Payload final ─────────────────────────────────────────────────────────
export interface AssetPayload {
  model: GenderModel;
  components: Record<number, { drawable: number; texture: number; palette: number }>;
  props: Record<number, { propIndex: number; propTextureIndex: number }>;
  overlays: Record<number, { index: number; opacity: number; firstColor: number; secondColor: number }>;
}

export interface AssetPickerProps {
  defaultGender?: GenderModel;
  initialSelections?: Partial<GenderSelections>;
  onChange?: (payload: AssetPayload, selections: PickerSelection) => void;
  onValidate?: (payload: AssetPayload) => void;
  assetBasePath?: string;
}
