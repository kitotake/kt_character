// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ASSET PICKER — HOOK v2 (texture + color)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useState, useCallback, useMemo } from "react";
import { CATEGORIES } from "./assetPicker.data";
import type {
  GenderModel,
  GenderSelections,
  PickerSelection,
  ItemSelection,
  AssetPayload,
  AssetCategory,
} from "./assetPicker.types";

interface UseAssetPickerOptions {
  defaultGender?: GenderModel;
  initialSelections?: Partial<GenderSelections>;
  assetBasePath?: string;
  onChange?: (payload: AssetPayload, sel: PickerSelection) => void;
}

export function useAssetPicker({
  defaultGender = "mp_f_freemode_01",
  initialSelections,
  assetBasePath = "./assets",
  onChange,
}: UseAssetPickerOptions = {}) {
  const [gender, setGenderState] = useState<GenderModel>(defaultGender);
  const [activeCatId, setActiveCatId] = useState<string | null>(null);
  const [catFilter, setCatFilter] = useState("");
  const [selections, setSelections] = useState<GenderSelections>({
    mp_f_freemode_01: initialSelections?.mp_f_freemode_01 ?? {},
    mp_m_freemode_01: initialSelections?.mp_m_freemode_01 ?? {},
  });

  // ── Catégories filtrées ─────────────────────────────────────────────────
  const categories = useMemo<AssetCategory[]>(() => {
    const cats = CATEGORIES[gender];
    if (!catFilter.trim()) return cats;
    const f = catFilter.toLowerCase();
    return cats.filter((c) => c.label.toLowerCase().includes(f) || c.id.includes(f));
  }, [gender, catFilter]);

  // ── Sélections actives ──────────────────────────────────────────────────
  const currentSel = useMemo<PickerSelection>(
    () => selections[gender],
    [selections, gender]
  );

  // ── Catégorie active ────────────────────────────────────────────────────
  const activeCat = useMemo<AssetCategory | null>(
    () => CATEGORIES[gender].find((c) => c.id === activeCatId) ?? null,
    [gender, activeCatId]
  );

  const selectionCount = Object.keys(currentSel).length;

  // ── Construction payload ────────────────────────────────────────────────
  const buildPayload = useCallback(
    (sel: PickerSelection, g: GenderModel): AssetPayload => {
      const cats = CATEGORIES[g];
      const components: AssetPayload["components"] = {};
      const props: AssetPayload["props"] = {};
      const overlays: AssetPayload["overlays"] = {};

      for (const [catId, item] of Object.entries(sel)) {
        const cat = cats.find((c) => c.id === catId);
        if (!cat) continue;

        if (cat.componentId != null) {
          components[cat.componentId] = {
            drawable: item.drawable,
            texture: item.texture,
            palette: 0,
          };
        } else if (cat.propAnchor != null) {
          props[cat.propAnchor] = {
            propIndex: item.drawable,
            propTextureIndex: item.texture,
          };
        } else if (cat.overlayId != null) {
          overlays[cat.overlayId] = {
            index: item.drawable,
            opacity: 1.0,
            firstColor: item.color ?? 0,
            secondColor: item.highlight ?? 0,
          };
        }
      }

      return { model: g, components, props, overlays };
    },
    []
  );

  // ── URL image ────────────────────────────────────────────────────────────
  const getImgSrc = useCallback(
    (cat: AssetCategory, drawable: number, texture = 0): string => {
      if (cat.direct) {
        return `${assetBasePath}/${gender}/${cat.id}/${drawable}.png`;
      }
      return `${assetBasePath}/${gender}/${cat.id}/${drawable}/${texture}.png`;
    },
    [gender, assetBasePath]
  );

  // ── Actions ──────────────────────────────────────────────────────────────
  const setGender = useCallback((g: GenderModel) => {
    setGenderState(g);
    setActiveCatId(null);
  }, []);

  const openCategory = useCallback((catId: string) => setActiveCatId(catId), []);

  /** Sélectionne / désélectionne un drawable */
  const pickItem = useCallback(
    (catId: string, drawable: number) => {
      setSelections((prev) => {
        const prevSel = prev[gender];
        const existing = prevSel[catId];
        let newSel: PickerSelection;

        if (existing?.drawable === drawable) {
          // désélection
          newSel = Object.fromEntries(Object.entries(prevSel).filter(([k]) => k !== catId));
        } else {
          newSel = {
            ...prevSel,
            [catId]: { drawable, texture: 0, color: existing?.color ?? 0, highlight: existing?.highlight ?? 0 },
          };
        }

        const next = { ...prev, [gender]: newSel };
        onChange?.(buildPayload(newSel, gender), newSel);
        return next;
      });
    },
    [gender, onChange, buildPayload]
  );

  /** Met à jour uniquement la texture du drawable actif */
  const pickTexture = useCallback(
    (catId: string, texture: number) => {
      setSelections((prev) => {
        const prevSel = prev[gender];
        const existing = prevSel[catId];
        if (!existing) return prev;

        const newSel: PickerSelection = {
          ...prevSel,
          [catId]: { ...existing, texture },
        };
        const next = { ...prev, [gender]: newSel };
        onChange?.(buildPayload(newSel, gender), newSel);
        return next;
      });
    },
    [gender, onChange, buildPayload]
  );

  /** Met à jour la couleur (firstColor) */
  const pickColor = useCallback(
    (catId: string, color: number) => {
      setSelections((prev) => {
        const prevSel = prev[gender];
        const existing = prevSel[catId];
        if (!existing) return prev;

        const newSel: PickerSelection = {
          ...prevSel,
          [catId]: { ...existing, color },
        };
        const next = { ...prev, [gender]: newSel };
        onChange?.(buildPayload(newSel, gender), newSel);
        return next;
      });
    },
    [gender, onChange, buildPayload]
  );

  /** Met à jour le highlight (secondColor) */
  const pickHighlight = useCallback(
    (catId: string, highlight: number) => {
      setSelections((prev) => {
        const prevSel = prev[gender];
        const existing = prevSel[catId];
        if (!existing) return prev;

        const newSel: PickerSelection = {
          ...prevSel,
          [catId]: { ...existing, highlight },
        };
        const next = { ...prev, [gender]: newSel };
        onChange?.(buildPayload(newSel, gender), newSel);
        return next;
      });
    },
    [gender, onChange, buildPayload]
  );

  const removeSelection = useCallback(
    (catId: string) => {
      setSelections((prev) => {
        const newSel = Object.fromEntries(
          Object.entries(prev[gender]).filter(([k]) => k !== catId)
        );
        const next = { ...prev, [gender]: newSel };
        onChange?.(buildPayload(newSel, gender), newSel);
        return next;
      });
    },
    [gender, onChange, buildPayload]
  );

  const clearAll = useCallback(() => {
    setSelections((prev) => {
      const next = { ...prev, [gender]: {} };
      onChange?.(buildPayload({}, gender), {});
      return next;
    });
  }, [gender, onChange, buildPayload]);

  const getPayload = useCallback(
    () => buildPayload(currentSel, gender),
    [buildPayload, currentSel, gender]
  );

  /** Retourne l'ItemSelection actuel pour une catégorie */
  const getItemSel = useCallback(
    (catId: string): ItemSelection | undefined => currentSel[catId],
    [currentSel]
  );

  return {
    gender, activeCatId, activeCat, catFilter, categories,
    currentSel, selectionCount,
    setGender, openCategory, pickItem, pickTexture, pickColor, pickHighlight,
    removeSelection, clearAll, setCatFilter, getPayload, getImgSrc, getItemSel,
  };
}
