// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ASSET PICKER — COMPOSANT v2 (texture + color)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useState, useCallback, memo } from "react";
import styles from "./AssetPicker.module.scss";
import { useAssetPicker } from "./useAssetPicker";
import { CATEGORIES, CATEGORY_GROUPS, HAIR_COLORS, MAKEUP_COLORS } from "./assetPicker.data";
import type { AssetPickerProps, AssetCategory, ItemSelection } from "./assetPicker.types";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SUB — AssetItem
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
interface AssetItemProps {
  index: number;
  imgSrc: string;
  selected: boolean;
  onPick: (index: number) => void;
}

const AssetItem = memo(({ index, imgSrc, selected, onPick }: AssetItemProps) => {
  const [imgFailed, setImgFailed] = useState(false);

  return (
    <div
      className={`${styles.assetItem} ${selected ? styles.selected : ""}`}
      onClick={() => onPick(index)}
      role="button"
      tabIndex={0}
      aria-label={`Variante ${index}${selected ? " (sélectionnée)" : ""}`}
      onKeyDown={(e) => e.key === "Enter" && onPick(index)}
    >
      <div className={styles.imgWrap}>
        {imgFailed ? (
          <div className={styles.imgFallback}>
            <span className={styles.fallbackIcon}>🖼️</span>
            <span className={styles.fallbackIdx}>#{index}</span>
          </div>
        ) : (
          <img
            src={imgSrc}
            alt={`Variante ${index}`}
            loading="lazy"
            onError={() => setImgFailed(true)}
          />
        )}
      </div>
      <div className={styles.itemLabel}>#{index}</div>
      {selected && <div className={styles.checkBadge}>✓</div>}
    </div>
  );
});
AssetItem.displayName = "AssetItem";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SUB — TextureThumb
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
interface TextureThumbProps {
  catId: string;
  drawable: number;
  texIdx: number;
  imgSrc: string;
  selected: boolean;
  onPick: (catId: string, tex: number) => void;
}

const TextureThumb = memo(({ catId, drawable: _drawable, texIdx, imgSrc, selected, onPick }: TextureThumbProps) => {
  const [failed, setFailed] = useState(false);

  return (
    <button
      className={`${styles.texThumb} ${selected ? styles.texSelected : ""}`}
      onClick={() => onPick(catId, texIdx)}
      title={`Texture #${texIdx}`}
    >
      {failed ? (
        <div className={styles.texFallback}>#{texIdx}</div>
      ) : (
        <img src={imgSrc} alt={`Texture ${texIdx}`} loading="lazy" onError={() => setFailed(true)} />
      )}
      <span className={styles.texBadge}>{texIdx}</span>
    </button>
  );
});
TextureThumb.displayName = "TextureThumb";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SUB — ColorGrid
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
interface ColorGridProps {
  palette: string[];
  label: string;
  value: number;
  onChange: (v: number) => void;
}

const ColorGrid = memo(({ palette, label, value, onChange }: ColorGridProps) => (
  <div className={styles.colorSection}>
    <div className={styles.colorLabel}>
      <div className={styles.colorPreviewDot} style={{ backgroundColor: palette[value] ?? "#000" }} />
      {label}
      <span className={styles.colorSubLabel}>#{value}</span>
    </div>
    <div className={styles.colorGrid}>
      {palette.map((color, i) => (
        <button
          key={i}
          className={`${styles.colorSwatch} ${value === i ? styles.swatchSelected : ""}`}
          style={{ backgroundColor: color }}
          title={`${label} ${i}`}
          onClick={() => onChange(i)}
        />
      ))}
    </div>
  </div>
));
ColorGrid.displayName = "ColorGrid";

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAIN — AssetPicker
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export default function AssetPicker({
  defaultGender = "mp_f_freemode_01",
  initialSelections,
  onChange,
  onValidate,
  assetBasePath = "./assets",
}: AssetPickerProps) {
  const [detailTab, setDetailTab] = useState<"texture" | "color">("texture");

  const {
    gender, activeCatId, activeCat, catFilter, categories,
    currentSel, selectionCount,
    setGender, openCategory, pickItem, pickTexture, pickColor, pickHighlight,
    removeSelection, clearAll, setCatFilter, getPayload, getImgSrc, getItemSel,
  } = useAssetPicker({ defaultGender, initialSelections, assetBasePath, onChange });

  // ── Sélection active dans la cat courante ─────────────────────────────
  const activeSel: ItemSelection | undefined = activeCat ? getItemSel(activeCat.id) : undefined;

  // ── Nombre de textures de la catégorie active ─────────────────────────
  const texCount = activeCat
    ? (activeCat.propAnchor != null
        ? (activeCat.propTextureCount ?? 8)
        : (activeCat.textureCount ?? 16))
    : 0;

  // ── Palette couleur ───────────────────────────────────────────────────
  const palette = activeCat?.colorType === "makeup" ? MAKEUP_COLORS
    : activeCat?.colorType === "hair" ? HAIR_COLORS
    : null;

  // ── Validation ────────────────────────────────────────────────────────
  const handleValidate = useCallback(() => {
    onValidate?.(getPayload());
  }, [onValidate, getPayload]);

  // ── Sidebar groupée ───────────────────────────────────────────────────
  const renderSidebar = () => {
    const allCats = CATEGORIES[gender];
    const filteredIds = new Set(categories.map((c) => c.id));

    return CATEGORY_GROUPS.map((group) => {
      const groupCats = group.ids
        .map((id) => allCats.find((c) => c.id === id))
        .filter((c): c is AssetCategory => !!c && filteredIds.has(c.id));

      if (groupCats.length === 0) return null;

      return (
        <div key={group.label}>
          <div className={styles.groupLabel}>{group.label}</div>
          {groupCats.map((cat) => {
            const sel = currentSel[cat.id];
            const hasSel = sel !== undefined;
            return (
              <button
                key={cat.id}
                className={`${styles.catBtn} ${activeCatId === cat.id ? styles.active : ""}`}
                onClick={() => openCategory(cat.id)}
                title={cat.label}
              >
                <span className={styles.catLeft}>
                  <span className={styles.catIcon}>{cat.icon}</span>
                  <span className={styles.catLabel}>{cat.label}</span>
                </span>
                <span className={`${styles.catTag} ${hasSel ? styles.selected : ""}`}>
                  {hasSel ? `#${sel.drawable}` : cat.count}
                </span>
              </button>
            );
          })}
        </div>
      );
    });
  };

  // ── Detail panel (texture + color) ────────────────────────────────────
  const renderDetailPanel = () => {
    if (!activeCat || !activeSel) return null;

    const hasTextures = texCount > 1;
    const hasColor = !!palette;
    if (!hasTextures && !hasColor) return null;

    const tabs = [
      hasTextures && { id: "texture" as const, label: "Textures" },
      hasColor    && { id: "color"   as const, label: "Couleurs" },
    ].filter(Boolean) as { id: "texture" | "color"; label: string }[];

    // Auto-switch si tab courant n'est plus disponible
    const currentTab = tabs.find((t) => t.id === detailTab) ? detailTab
      : tabs[0]?.id ?? "texture";

    return (
      <div className={styles.detailPanel}>
        {/* Tabs */}
        <div className={styles.detailHeader}>
          {tabs.map((t) => (
            <button
              key={t.id}
              className={`${styles.detailTab} ${currentTab === t.id ? styles.activeTab : ""}`}
              onClick={() => setDetailTab(t.id)}
            >
              {t.label}
            </button>
          ))}
        </div>

        <div className={styles.detailBody}>
          {/* TEXTURES */}
          {currentTab === "texture" && hasTextures && (
            <div className={styles.texStrip}>
              {Array.from({ length: texCount }, (_, i) => (
                <TextureThumb
                  key={i}
                  catId={activeCat.id}
                  drawable={activeSel.drawable}
                  texIdx={i}
                  imgSrc={getImgSrc(activeCat, activeSel.drawable, i)}
                  selected={activeSel.texture === i}
                  onPick={pickTexture}
                />
              ))}
            </div>
          )}

          {/* COULEURS */}
          {currentTab === "color" && hasColor && palette && (
            <div className={styles.colorSection} style={{ gap: 12 }}>
              <ColorGrid
                palette={palette}
                label={activeCat.colorType === "hair" ? "Couleur" : "Teinte"}
                value={activeSel.color ?? 0}
                onChange={(v) => pickColor(activeCat.id, v)}
              />
              {activeCat.colorType === "hair" && (
                <ColorGrid
                  palette={palette}
                  label="Reflet"
                  value={activeSel.highlight ?? 0}
                  onChange={(v) => pickHighlight(activeCat.id, v)}
                />
              )}
            </div>
          )}
        </div>
      </div>
    );
  };

  // ── Barre de sélections ───────────────────────────────────────────────
  const renderSelBar = () => {
    const entries = Object.entries(currentSel);
    const allCats = CATEGORIES[gender];

    if (entries.length === 0) {
      return (
        <div className={styles.selBar}>
          <div className={styles.selPlaceholder}>
            <span>👆</span>
            Cliquez sur une miniature pour la sélectionner
          </div>
          <div className={styles.actionsRow}>
            <button className={styles.validateBtn} disabled>
              ✓ Valider la sélection
            </button>
          </div>
        </div>
      );
    }

    return (
      <div className={styles.selBar}>
        <div className={styles.selBarTop}>
          <span className={styles.selBarTitle}>
            <span className={styles.selBarDot} />
            {entries.length} sélectionné{entries.length > 1 ? "s" : ""}
          </span>
          <button className={styles.clearAllBtn} onClick={clearAll}>🗑️ Tout effacer</button>
        </div>

        <div className={styles.selRows}>
          {entries.map(([catId, item]) => {
            const cat = allCats.find((c) => c.id === catId);
            const colorDot = (item.color !== undefined && cat?.colorType && cat.colorType !== "none")
              ? (cat.colorType === "hair" ? HAIR_COLORS[item.color] : MAKEUP_COLORS[item.color])
              : null;

            return (
              <div key={catId} className={styles.selRow}>
                <span className={styles.selRowLeft}>
                  <span className={styles.selRowIcon}>{cat?.icon ?? "📦"}</span>
                  <span className={styles.selRowLabel}>{cat?.label ?? catId}</span>
                </span>
                <span className={styles.selRowRight}>
                  {colorDot && (
                    <span className={styles.selRowColor} style={{ backgroundColor: colorDot }} />
                  )}
                  <span className={styles.selRowCode}>#{item.drawable}</span>
                  {item.texture > 0 && (
                    <span className={styles.selRowCode} style={{ opacity: 0.6 }}>t{item.texture}</span>
                  )}
                  <button
                    className={styles.selRowDel}
                    onClick={() => removeSelection(catId)}
                    aria-label={`Retirer ${cat?.label}`}
                  >
                    ✕
                  </button>
                </span>
              </div>
            );
          })}
        </div>

        <div className={styles.actionsRow}>
          <button
            className={styles.validateBtn}
            onClick={handleValidate}
            disabled={entries.length === 0}
          >
            ✓ Valider la sélection ({entries.length})
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className={styles.picker}>

      {/* ── Topbar ─────────────────────────────────────────────────────── */}
      <div className={styles.topbar}>
        <button
          className={`${styles.genderBtn} ${gender === "mp_f_freemode_01" ? styles.active : ""}`}
          onClick={() => setGender("mp_f_freemode_01")}
        >
          <span className={styles.genderIcon}>♀</span> Femme
        </button>
        <button
          className={`${styles.genderBtn} ${gender === "mp_m_freemode_01" ? styles.active : ""}`}
          onClick={() => setGender("mp_m_freemode_01")}
        >
          <span className={styles.genderIcon}>♂</span> Homme
        </button>
        <input
          className={styles.searchInput}
          type="text"
          placeholder="Filtrer catégories…"
          value={catFilter}
          onChange={(e) => setCatFilter(e.target.value)}
        />
        <span className={`${styles.totalBadge} ${selectionCount > 0 ? styles.hasItems : ""}`}>
          {selectionCount} sélectionné{selectionCount > 1 ? "s" : ""}
        </span>
      </div>

      {/* ── Body ───────────────────────────────────────────────────────── */}
      <div className={styles.body}>

        {/* Sidebar */}
        <div className={styles.sidebar}>{renderSidebar()}</div>

        {/* Panneau droit */}
        <div className={styles.rightPanel}>

          {/* Header */}
          <div className={styles.panelHeader}>
            <span className={styles.panelTitle}>
              {activeCat ? `${activeCat.icon} ${activeCat.label}` : "Choisir une catégorie"}
            </span>
            {activeCat && activeSel && (
              <span className={styles.panelInfo}>
                #{activeSel.drawable}
                {activeSel.texture > 0 && ` · t${activeSel.texture}`}
              </span>
            )}
          </div>

          {/* Grille d'assets */}
          <div className={styles.gridWrapper}>
            {!activeCat ? (
              <div className={styles.emptyState}>
                <span className={styles.emptyIcon}>🗂️</span>
                <span className={styles.emptyTitle}>Aucune catégorie sélectionnée</span>
                <span className={styles.emptyHint}>Choisissez une catégorie dans le menu de gauche</span>
              </div>
            ) : (
              <div className={styles.assetGrid}>
                {Array.from({ length: activeCat.count }, (_, i) => (
                  <AssetItem
                    key={i}
                    index={i}
                    imgSrc={getImgSrc(activeCat, i, activeSel?.texture ?? 0)}
                    selected={activeSel?.drawable === i}
                    onPick={(idx) => pickItem(activeCat.id, idx)}
                  />
                ))}
              </div>
            )}
          </div>

          {/* ── Detail panel : textures + couleurs ── */}
          {renderDetailPanel()}

          {/* Barre de sélection */}
          {renderSelBar()}
        </div>
      </div>
    </div>
  );
}
