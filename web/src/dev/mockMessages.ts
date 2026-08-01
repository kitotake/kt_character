import { mockCharacters } from "./mockCharacters";

export function sendNuiMessage(data: unknown) {
  window.dispatchEvent(
    new MessageEvent("message", {
      data,
    })
  );
}

export function openCreator() {
  sendNuiMessage({
    type: "open",
  });

  setTimeout(() => {
    sendNuiMessage({
      type: "setIdentifier",
      identifier: "license:dev_mock_license_abc123",
      unique_id: "",
    });
  }, 100);
}

export function openCharacterSelection() {
  sendNuiMessage({
    action: "openCharacterSelection",
    characters: mockCharacters,
    slots: 3,
  });
}

export function closeUI() {
  sendNuiMessage({
    type: "close",
    action: "closeUI",
  });
}

export function sendError() {
  sendNuiMessage({
    type: "error",
    message: "[MOCK] Erreur simulée — identifiant introuvable",
  });
}

export function sendSuccessNotification() {
  sendNuiMessage({
    type: "notification",
    variant: "success",
    message: "Personnage créé avec succès",
  });
}