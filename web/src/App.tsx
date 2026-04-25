// web/src/App.tsx
// Gère les deux protocoles NUI :
//   - type="..." pour le Creator (kt_character)
//   - action="..." pour CharacterSelect (union/kt_character)

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
  const [selectVisible, setSelectVisible] = useState(false);
  const [selectChars, setSelectChars]     = useState<Character[]>([]);
  const [selectSlots, setSelectSlots]     = useState(3);

  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data;
      if (!msg) return;

      // FIX: le client Lua envoie action= pour la sélection
      // et type= pour le creator — on gère les deux
      const key = msg.action ?? msg.type;

      switch (key) {
        case "openCharacterSelection":
          setSelectChars(msg.characters || []);
          setSelectSlots(msg.slots || 3);
          setSelectVisible(true);
          break;

        // Fermeture globale (après spawn ou erreur)
        case "close":
          setSelectVisible(false);
          break;

        default:
          // Les autres messages (open, setIdentifier, error, etc.)
          // sont gérés directement par Creator via useCreator.ts
          break;
      }
    };

    window.addEventListener("message", handler);
    return () => window.removeEventListener("message", handler);
  }, []);

  return (
    <>
      {/* Creator de personnage */}
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