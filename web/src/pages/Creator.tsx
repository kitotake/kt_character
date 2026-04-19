import styles from "./Creator.module.sass";
import { useState, useCallback } from "react";
import Tabs from "../components/Tabs";
import Slider from "../components/Slider";
import Category from "../components/Category";
import ColorPicker from "../components/ColorPicker";

interface CreatorData {
  hair: number;
  beard: number;
  hairColor: number;
}

export default function Creator() {
  const [tab, setTab] = useState<string>("face");
  const [data, setData] = useState<CreatorData>({
    hair: 0,
    beard: 0,
    hairColor: 0,
  });
  const [error, setError] = useState<string>("");

  // Get resource name from window (for FiveM/RedM integration)
  const getResourceName = useCallback((): string => {
    if (typeof window !== "undefined" && (window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return "default-resource";
  }, []);

  const update = useCallback(
    async (key: keyof CreatorData, value: number) => {
      const updated = { ...data, [key]: value };
      setData(updated);
      setError("");

      try {
        const response = await fetch(
          `https://${getResourceName()}/update`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify(updated),
          }
        );

        if (!response.ok) {
          setError(`Erreur: ${response.statusText}`);
        }
      } catch (err) {
        setError("Erreur de connexion");
        console.error("Update error:", err);
      }
    },
    [data, getResourceName]
  );

  return (
    <div className={styles.container}>
      <Tabs tab={tab} setTab={setTab} />

      {error && <div className={styles.error}>{error}</div>}

      {tab === "face" && (
        <Category title="Visage">
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
        <Category title="Cheveux">
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
      )}
    </div>
  );
}