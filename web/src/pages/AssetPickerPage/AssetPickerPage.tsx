// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ASSET PICKER PAGE — v3
// Enveloppe fine autour d'AssetPicker : convertit son payload générique
// (AssetPayload) vers les types kt_character et relaie preview/validation
// au parent (ClothingWindow).
//
// v3 : le mini-aperçu SVG (silhouette + stats Items/Tex/Coul) qui vivait
// ici a été retiré à la demande — il n'avait aucune donnée ni callback Lua
// qui lui soit propre, sa suppression n'affecte donc que ce fichier et son
// SCSS. Le bouton "Reset" qui vivait à côté de lui a été déplacé dans le
// footer de ClothingWindow.tsx (voir ce fichier).
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useCallback } from "react";
import styles from "./AssetPickerPage.module.scss";
import { AssetPicker } from "../../components/AssetPicker";
import type { AssetPayload, GenderModel } from "../../components/AssetPicker";
import type { ClothingComponents, Props, HeadOverlays } from "../../types/appearance.types";

// ── Conversions payload → types kt_character ──────────────────────────────
function payloadToComponents(payload: AssetPayload): ClothingComponents {
  const result: ClothingComponents = {};
  for (const [key, val] of Object.entries(payload.components)) {
    result[Number(key)] = { drawable: val.drawable, texture: val.texture, palette: val.palette };
  }
  return result;
}

function payloadToProps(payload: AssetPayload): Props {
  const result: Props = {};
  for (const [key, val] of Object.entries(payload.props)) {
    result[Number(key)] = { propIndex: val.propIndex, propTextureIndex: val.propTextureIndex };
  }
  return result;
}

function payloadToOverlays(payload: AssetPayload): HeadOverlays {
  const result: HeadOverlays = {};
  for (const [key, val] of Object.entries(payload.overlays)) {
    result[Number(key)] = {
      index: val.index,
      opacity: val.opacity,
      firstColor: val.firstColor,
      secondColor: val.secondColor,
    };
  }
  return result;
}

// ── Props ─────────────────────────────────────────────────────────────────
interface AssetPickerPageProps {
  gender: GenderModel;
  // Incrémenté par ClothingWindow au clic sur "Reset" : AssetPicker gère ses
  // propres sélections en interne (useAssetPicker), donc changer sa `key`
  // est le moyen le plus sûr de vraiment les vider, sans dupliquer cette
  // logique ici ni toucher à useAssetPicker.ts.
  resetKey?: number;
  onPreview?: (components: ClothingComponents, props: Props, overlays: HeadOverlays) => void;
  onValidate?: (components: ClothingComponents, props: Props, overlays: HeadOverlays) => void;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export default function AssetPickerPage({
  gender,
  resetKey,
  onPreview,
  onValidate,
}: AssetPickerPageProps) {
  const handleChange = useCallback(
    (payload: AssetPayload) => {
      onPreview?.(
        payloadToComponents(payload),
        payloadToProps(payload),
        payloadToOverlays(payload)
      );
    },
    [onPreview]
  );

  const handleValidate = useCallback(
    (payload: AssetPayload) => {
      onValidate?.(
        payloadToComponents(payload),
        payloadToProps(payload),
        payloadToOverlays(payload)
      );
    },
    [onValidate]
  );

  return (
    <div className={styles.wrapper}>
      <div className={styles.layout}>
        <div className={styles.pickerArea}>
          <AssetPicker
            key={resetKey}
            defaultGender={gender}
            assetBasePath="./assets"
            onChange={handleChange}
            onValidate={handleValidate}
          />
        </div>
      </div>
    </div>
  );
}
