// web/src/App.tsx
// Intègre CharacterSelect dans le flux NUI en plus du Creator existant

import { useState, useEffect } from "react";
import Creator from "./pages/Creator";
import CharacterSelect from "./pages/CharacterSelect";
import "./style/global.scss";

interface Character {
  id: number;
  unique_id: string;
  firstname: string;
  lastname: string;
  dateofbirth: string;
  gender: string;
  model: string;
  job: string;
  job_grade: number;
  health: number;
  armor: number;
}

export default function App() {
  // ── État sélection ────────────────────────────────────────────────────
  const [selectVisible, setSelectVisible] = useState(false);
  const [selectChars, setSelectChars]     = useState<Character[]>([]);
  const [selectSlots, setSelectSlots]     = useState(1);

  // ── NUI message handler ───────────────────────────────────────────────
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg?.action) return;

      switch (msg.action) {
        // Ouverture sélection personnage
        case "openCharacterSelection":
          setSelectChars(msg.characters || []);
          setSelectSlots(msg.slots || 1);
          setSelectVisible(true);
          break;

        // Fermeture (après doSpawn ou erreur critique)
        case "close":
          setSelectVisible(false);
          break;

        // Erreur à afficher dans la sélection
        case "showError":
          // Géré dans CharacterSelect via message Notifications
          break;

        default:
          break;
      }
    };

    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  }, []);

  return (
    <>
      {/* Creator de personnage (kt_character) */}
      <Creator />

      {/* Sélection de personnage */}
      <CharacterSelect
        visible={selectVisible}
        characters={selectChars}
        slots={selectSlots}
        
      />
    </>
  );
}