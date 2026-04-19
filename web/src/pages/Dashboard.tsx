import styles from "./Dashboard.module.scss";
import { useState } from "react";
import Preview from "../components/Preview/Preview";
import Tabs from "../components/Tabs/Tabs";
import Category from "../components/Category/Category";
import Slider from "../components/Slider/Slider";
import ColorPicker from "../components/ColorPicker/ColorPicker";
import Presets from "../components/Presets/Presets";
import ExportAdvanced from "../components/ExportAdvanced/ExportAdvanced";
import Comparison from "../components/Comparison/Comparison";
import { usePresets } from "../hooks/usePresets.ts";
import { useLocalStorage } from "../hooks/useLocalStorage.ts";
import { BarChart3, Share2, Copy, Eye, Settings } from "lucide-react";

interface CreatorData {
  hair: number;
  beard: number;
  hairColor: number;
}

export default function Dashboard() {
  const [tab, setTab] = useState<string>("face");
  const [data, setData] = useLocalStorage<CreatorData>("character-data", {
    hair: 0,
    beard: 0,
    hairColor: 0,
  });
  const [error, setError] = useState<string>("");
  const [successMessage, setSuccessMessage] = useState<string>("");
  const [showExport, setShowExport] = useState(false);
  const [showComparison, setShowComparison] = useState(false);
  const [showPreview, setShowPreview] = useState(false);

  const {
    presets,
    selectedPresetId,
    addPreset,
    deletePreset,
    selectPreset,
    exportPresets,
    importPresets,
  } = usePresets();

  const getResourceName = (): string => {
    if (typeof window !== "undefined" && (window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return "default-resource";
  };

  const update = async (key: keyof CreatorData, value: number) => {
    const updated = { ...data, [key]: value };
    setData(updated);
    setError("");

    try {
      const response = await fetch(
        `https://${getResourceName()}/update`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(updated),
        }
      );

      if (!response.ok) {
        setError(`Erreur: ${response.statusText}`);
      } else {
        setSuccessMessage("✓ Changements sauvegardés");
        setTimeout(() => setSuccessMessage(""), 2000);
      }
    } catch (err) {
      setError("Erreur de connexion");
      console.error("Update error:", err);
    }
  };

  const handleSelectPreset = (preset: any) => {
    setData(preset.data);
    selectPreset(preset.id);
    setSuccessMessage(`✓ Profil "${preset.name}" chargé`);
    setTimeout(() => setSuccessMessage(""), 2000);
  };

  const handleCopySettings = () => {
    const text = `Hair: ${data.hair} | Beard: ${data.beard} | Color: ${data.hairColor}`;
    navigator.clipboard.writeText(text);
    setSuccessMessage("✓ Paramètres copiés");
    setTimeout(() => setSuccessMessage(""), 2000);
  };

  return (
    <div className={styles.dashboard}>
      {/* Sidebar Left - Preview & Stats */}
      <div className={styles.sidebar}>
        <div className={styles.previewSection}>
          <div className={styles.previewCard}>
            <Preview data={data} />
          </div>

          <div className={styles.statsCard}>
            <h3>Statistiques</h3>
            <div className={styles.statRow}>
              <span>Profils sauvegardés</span>
              <strong>{presets.length}</strong>
            </div>
            <div className={styles.statRow}>
              <span>Profil actif</span>
              <strong>
                {selectedPresetId
                  ? presets.find((p) => p.id === selectedPresetId)?.name
                  : "Nouveau"}
              </strong>
            </div>
          </div>

          <div className={styles.quickActions}>
            <button
              className={styles.actionBtn}
              onClick={handleCopySettings}
              title="Copier les paramètres"
            >
              <Copy size={16} />
              <span>Copier</span>
            </button>
            <button
              className={styles.actionBtn}
              onClick={() => setShowPreview(!showPreview)}
              title="Agrandir l'aperçu"
            >
              <Eye size={16} />
              <span>Agrandir</span>
            </button>
            {presets.length > 1 && (
              <button
                className={styles.actionBtn}
                onClick={() => setShowComparison(true)}
                title="Comparer les presets"
              >
                <BarChart3 size={16} />
                <span>Comparer</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className={styles.main}>
        {/* Header */}
        <div className={styles.header}>
          <div className={styles.headerContent}>
            <h1>Character Creator</h1>
            <p>Créez et personnalisez vos caractères</p>
          </div>
          <div className={styles.headerActions}>
            <button
              className={styles.iconBtn}
              onClick={() => setShowExport(true)}
              title="Exporter"
            >
              <Share2 size={20} />
            </button>
            <button className={styles.iconBtn} title="Paramètres">
              <Settings size={20} />
            </button>
          </div>
        </div>

        {/* Messages */}
        {error && <div className={styles.errorMessage}>{error}</div>}
        {successMessage && <div className={styles.successMessage}>{successMessage}</div>}

        {/* Tabs & Content */}
        <Tabs tab={tab} setTab={setTab} />

        <div className={styles.content}>
          {tab === "face" && (
            <Category title="Visage" icon="◉">
              <Slider
                label="Barbe"
                min={0}
                max={28}
                value={data.beard}
                onChange={(v) => update("beard", v)}
              />
            </Category>
          )}

          {tab === "hair" && (
            <>
              <Category title="Cheveux" icon="✦">
                <Slider
                  label="Style"
                  min={0}
                  max={75}
                  value={data.hair}
                  onChange={(v) => update("hair", v)}
                />

                <ColorPicker
                  label="Couleur"
                  value={data.hairColor}
                  onChange={(v) => update("hairColor", v)}
                />
              </Category>
            </>
          )}

          {/* Presets Section */}
          <Presets
            presets={presets}
            selectedId={selectedPresetId}
            onSelect={handleSelectPreset}
            onDelete={deletePreset}
            onAdd={(name, presetData) => {
              addPreset(name, presetData);
              setSuccessMessage(`✓ Profil "${name}" sauvegardé`);
              setTimeout(() => setSuccessMessage(""), 2000);
            }}
            onExport={exportPresets}
            onImport={importPresets}
            currentData={data}
          />
        </div>
      </div>

      {/* Modals */}
      
      {showComparison && (
        <Comparison
          presets={presets}
          onClose={() => setShowComparison(false)}
        />
      )}

      {/* Fullscreen Preview Modal */}
      {showPreview && (
        <div className={styles.fullscreenPreview}>
          <button
            className={styles.closePreview}
            onClick={() => setShowPreview(false)}
          >
            ✕
          </button>
          <div className={styles.previewContent}>
            <Preview data={data} />
          </div>
        </div>
      )}
    </div>
  );
}