// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Creator.tsx — Orchestrateur
// Deux fenêtres React indépendantes, jamais montées en même temps :
//   - IdentityWindow (prénom/nom/naissance/sexe → Continuer)
//   - ClothingWindow (aperçu/tenue/caméra → Créer le personnage)
// Pas de wizard à étapes, pas de modal partagée : `phase` détermine
// uniquement laquelle des deux est montée. La transition fluide (fermeture
// de la première puis ouverture de la seconde) est gérée localement dans
// IdentityWindow au moment du clic sur "Continuer", avant d'appeler
// `completeIdentity` qui bascule réellement `phase`.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import { useCreator } from "../../hooks/useCreator";
import IdentityWindow from "./IdentityWindow";
import ClothingWindow from "./ClothingWindow";

export default function Creator() {
  const {
    visible, phase, errors, serverError, submitting,
    identity, closeUI, completeIdentity, handleSubmit, camControl, getAge,
    updateIdentity, updateComponents, updateProps, updateHeadOverlays,
  } = useCreator();

  if (!visible) return null;

  if (phase === "identity") {
    return (
      <IdentityWindow
        identity={identity}
        errors={errors}
        serverError={serverError}
        getAge={getAge}
        updateIdentity={updateIdentity}
        onContinue={completeIdentity}
        onClose={() => void closeUI()}
      />
    );
  }

  return (
    <ClothingWindow
      gender={identity.gender}
      submitting={submitting}
      serverError={serverError}
      camControl={camControl}
      onPreview={(comps, prps, overlays) => {
        updateComponents(comps);
        updateProps(prps);
        updateHeadOverlays(overlays);
      }}
      onClearAll={() => {
        updateComponents({});
        updateProps({});
      }}
      onSubmit={() => void handleSubmit()}
      onClose={() => void closeUI()}
    />
  );
}
