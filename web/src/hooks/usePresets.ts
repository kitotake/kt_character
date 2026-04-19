import { useState, useCallback } from "react";
import { useLocalStorage } from "./useLocalStorage";

export interface Preset {
  id: string;
  name: string;
  data: any;
  createdAt: number;
}

export function usePresets() {
  const [presets, setPresets] = useLocalStorage<Preset[]>("character-presets", []);
  const [selectedPresetId, setSelectedPresetId] = useState<string | null>(null);

  const addPreset = useCallback(
    (name: string, data: any) => {
      const newPreset: Preset = {
        id: `preset_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
        name,
        data: { ...data },
        createdAt: Date.now(),
      };
      setPresets([...presets, newPreset]);
      setSelectedPresetId(newPreset.id);
      return newPreset;
    },
    [presets, setPresets]
  );

  const deletePreset = useCallback(
    (id: string) => {
      setPresets(presets.filter((p) => p.id !== id));
      if (selectedPresetId === id) setSelectedPresetId(null);
    },
    [presets, setPresets, selectedPresetId]
  );

  const selectPreset = useCallback((id: string) => {
    setSelectedPresetId(id);
  }, []);

  const updatePreset = useCallback(
    (id: string, data: any) => {
      setPresets(presets.map((p) => (p.id === id ? { ...p, data: { ...data } } : p)));
    },
    [presets, setPresets]
  );

  const exportPresets = useCallback((): string => {
    return JSON.stringify(
      {
        version: 1,
        exportedAt: new Date().toISOString(),
        presets,
      },
      null,
      2
    );
  }, [presets]);

  const importPresets = useCallback(
    (json: string): boolean => {
      try {
        const parsed = JSON.parse(json);
        const importedPresets: Preset[] = Array.isArray(parsed)
          ? parsed
          : parsed.presets ?? [];
        setPresets([...presets, ...importedPresets]);
        return true;
      } catch {
        return false;
      }
    },
    [presets, setPresets]
  );

  return {
    presets,
    selectedPresetId,
    addPreset,
    deletePreset,
    selectPreset,
    updatePreset,
    exportPresets,
    importPresets,
  };
}