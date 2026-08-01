import {
  openCreator,
  openCharacterSelection,
  closeUI,
  sendError,
  sendSuccessNotification,
} from "./mockMessages";

declare global {
  interface Window {
    GetParentResourceName?: () => string;
    __KT_CHARACTER_MOCK__?: boolean;
  }
}

if (!window.__KT_CHARACTER_MOCK__) {
  window.__KT_CHARACTER_MOCK__ = true;

  // ----------------------------------------------------
  // Mock FiveM
  // ----------------------------------------------------

  window.GetParentResourceName = () => "kt_character";

  const originalFetch = window.fetch.bind(window);

  window.fetch = async (
    input: RequestInfo | URL,
    init?: RequestInit
  ) => {
    const url =
      typeof input === "string"
        ? input
        : input.toString();

    if (url.startsWith("https://kt_character/")) {
      const endpoint = url.replace(
        "https://kt_character/",
        ""
      );

      let body: unknown = {};

      try {
        body = JSON.parse(
          (init?.body as string) ?? "{}"
        );
      } catch {}

      console.log(
        `%c[NUI MOCK] → ${endpoint}`,
        "color:#00d9ff",
        body
      );

      switch (endpoint) {
        case "close":
          console.log(
            "[NUI MOCK] Fermeture demandée"
          );
          break;

        case "tabChange":
          console.log(
            "[NUI MOCK] Onglet changé",
            body
          );
          break;

        case "update":
          console.log(
            "[NUI MOCK] Preview update",
            body
          );
          break;

        case "cameraControl":
          console.log(
            "[NUI MOCK] Camera control",
            body
          );
          break;

        case "createCharacter":
          console.log(
            "[NUI MOCK] Création personnage",
            body
          );

          await new Promise((resolve) =>
            setTimeout(resolve, 750)
          );

          sendSuccessNotification();

          break;

        default:
          console.warn(
            `[NUI MOCK] Endpoint inconnu : ${endpoint}`
          );
      }

      return new Response(
        JSON.stringify({
          success: true,
          endpoint,
        }),
        {
          status: 200,
          headers: {
            "Content-Type":
              "application/json",
          },
        }
      );
    }

    return originalFetch(input, init);
  };

  // ----------------------------------------------------
  // Raccourcis clavier DEV
  // ----------------------------------------------------

  window.addEventListener("keydown", (e) => {
    switch (e.key.toLowerCase()) {
      case "o":
        console.log(
          "[NUI MOCK] O → Open Creator"
        );
        openCreator();
        break;

      case "s":
        console.log(
          "[NUI MOCK] S → Character Select"
        );
        openCharacterSelection();
        break;

      case "e":
        console.log(
          "[NUI MOCK] E → Error"
        );
        sendError();
        break;

      case "c":
        console.log(
          "[NUI MOCK] C → Close"
        );
        closeUI();
        break;
    }
  });

  console.log(
    `%c
╔════════════════════════════╗
║      KT CHARACTER MOCK    ║
╠════════════════════════════╣
║ O → Open Creator          ║
║ S → Character Selection   ║
║ E → Error                 ║
║ C → Close                 ║
╚════════════════════════════╝
`,
    "color:#00d9ff;font-weight:bold;"
  );

  // ----------------------------------------------------
  // Ouverture auto
  // ----------------------------------------------------

  openCreator();
}