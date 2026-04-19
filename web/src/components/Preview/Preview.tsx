import styles from "./Presets.module.sass";
import { useState } from "react";

interface Preset {
  id: string;
  name: string;
  data: any;
  createdAt: number;
}

interface PresetsProps {
  presets: Preset[];
  selectedId: string | null;
  onSelect: (preset: Preset) => void;
  onDelete: (id: string) => void;
  onAdd: (name: string, data: any) => void;
  onExport?: () => void;
  onImport?: (json: string) => void;
  currentData: any;
}

export default function Presets({
  presets,
  selectedId,
  onSelect,
  onDelete,
  onAdd,
  currentData,
}: PresetsProps) {
  const [showForm, setShowForm] = useState(false);
  const [name, setName] = useState("");

  const handleSave = () => {
    if (!name.trim()) return;
    onAdd(name.trim(), currentData);
    setName("");
    setShowForm(false);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSave();
    if (e.key === "Escape") setShowForm(false);
  };

  const formatDate = (ts: number) => {
    return new Date(ts).toLocaleDateString("fr-FR", {
      day: "2-digit",
      month: "short",
    });
  };

  return (
    <div className={styles.section}>
      <div className={styles.header}>
        <span className={styles.title}>Presets ({presets.length})</span>
        {!showForm && (
          <button
            className={styles.addBtn}
            onClick={() => setShowForm(true)}
          >
            + Sauvegarder
          </button>
        )}
      </div>

      {/* Save form */}
      {showForm && (
        <div className={styles.form}>
          <input
            className={styles.input}
            type="text"
            placeholder="Nom du preset..."
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={handleKeyDown}
            autoFocus
          />
          <button className={styles.saveBtn} onClick={handleSave}>
            ✓
          </button>
          <button
            className={styles.cancelBtn}
            onClick={() => setShowForm(false)}
          >
            ✕
          </button>
        </div>
      )}

      {/* Preset list */}
      {presets.length === 0 ? (
        <div className={styles.empty}>Aucun preset sauvegardé</div>
      ) : (
        <div className={styles.list}>
          {presets.map((preset) => (
            <div
              key={preset.id}
              className={`${styles.item} ${selectedId === preset.id ? styles.selected : ""}`}
              onClick={() => onSelect(preset)}
            >
              <div className={styles.dot} />
              <div className={styles.info}>
                <div className={styles.name}>{preset.name}</div>
                <div className={styles.meta}>
                  Cheveux: {preset.data.hair} · Barbe: {preset.data.beard} · {formatDate(preset.createdAt)}
                </div>
              </div>
              <div className={styles.actions}>
                <button
                  className={`${styles.actionBtn} ${styles.danger}`}
                  onClick={(e) => {
                    e.stopPropagation();
                    onDelete(preset.id);
                  }}
                  title="Supprimer"
                >
                  ✕
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}