import styles from "./Comparison.module.scss";
import { useState } from "react";
import { X } from "lucide-react";

interface ComparisonProps {
  presets: any[];
  onClose: () => void;
}

export default function Comparison({ presets, onClose }: ComparisonProps) {
  const [selected, setSelected] = useState<[string, string] | null>(null);

  if (!selected) {
    return (
      <div className={styles.overlay}>
        <div className={styles.modal}>
          <div className={styles.header}>
            <h2>Comparer les Presets</h2>
            <button className={styles.closeBtn} onClick={onClose}>
              <X size={20} />
            </button>
          </div>

          <div className={styles.presetGrid}>
            {presets.map((p1, i1) => (
              <div key={i1} className={styles.compareGroup}>
                <button
                  className={styles.presetCard}
                  onClick={() =>
                    setSelected([p1.id, presets[0].id === p1.id ? presets[1]?.id : presets[0]?.id])
                  }
                >
                  <p className={styles.name}>{p1.name}</p>
                  <div className={styles.preview}>
                    <div className={styles.stat}>
                      Cheveux: <strong>{p1.data.hair}</strong>
                    </div>
                    <div className={styles.stat}>
                      Barbe: <strong>{p1.data.beard}</strong>
                    </div>
                  </div>
                </button>

                {presets.map((p2, i2) =>
                  i1 < i2 ? (
                    <button
                      key={`${i1}-${i2}`}
                      className={`${styles.presetCard} ${styles.vs}`}
                      onClick={() => setSelected([p1.id, p2.id])}
                    >
                      <p className={styles.name}>{p2.name}</p>
                      <div className={styles.preview}>
                        <div className={styles.stat}>
                          Cheveux: <strong>{p2.data.hair}</strong>
                        </div>
                        <div className={styles.stat}>
                          Barbe: <strong>{p2.data.beard}</strong>
                        </div>
                      </div>
                    </button>
                  ) : null
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  const preset1 = presets.find((p) => p.id === selected[0])!;
  const preset2 = presets.find((p) => p.id === selected[1])!;

  const diffColor = (v1: number, v2: number) => {
    if (v1 > v2) return styles.higher;
    if (v1 < v2) return styles.lower;
    return styles.equal;
  };

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <div className={styles.header}>
          <h2>Comparaison</h2>
          <button className={styles.closeBtn} onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        <div className={styles.comparison}>
          {/* Preset 1 */}
          <div className={styles.side}>
            <h3>{preset1.name}</h3>
            <div className={styles.stats}>
              <div className={`${styles.stat} ${diffColor(preset1.data.hair, preset2.data.hair)}`}>
                <span>Cheveux</span>
                <strong>{preset1.data.hair}</strong>
              </div>
              <div className={`${styles.stat} ${diffColor(preset1.data.beard, preset2.data.beard)}`}>
                <span>Barbe</span>
                <strong>{preset1.data.beard}</strong>
              </div>
              <div className={styles.stat}>
                <span>Couleur</span>
                <strong>{preset1.data.hairColor}/20</strong>
              </div>
            </div>
          </div>

          {/* Divider */}
          <div className={styles.divider} />

          {/* Preset 2 */}
          <div className={styles.side}>
            <h3>{preset2.name}</h3>
            <div className={styles.stats}>
              <div className={`${styles.stat} ${diffColor(preset2.data.hair, preset1.data.hair)}`}>
                <span>Cheveux</span>
                <strong>{preset2.data.hair}</strong>
              </div>
              <div className={`${styles.stat} ${diffColor(preset2.data.beard, preset1.data.beard)}`}>
                <span>Barbe</span>
                <strong>{preset2.data.beard}</strong>
              </div>
              <div className={styles.stat}>
                <span>Couleur</span>
                <strong>{preset2.data.hairColor}/20</strong>
              </div>
            </div>
          </div>
        </div>

        <div className={styles.actions}>
          <button className={styles.backBtn} onClick={() => setSelected(null)}>
            Retour
          </button>
          <button className={styles.closeActionBtn} onClick={onClose}>
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
}