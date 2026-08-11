import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";

import "./index.css";
import { isEnvBrowser } from "./utils/misc";

if (import.meta.env.DEV) {
  import("./dev/nui.mock");
}

const root = document.getElementById("root");

if (isEnvBrowser() && root) {
  root.style.backgroundImage = 'url("https://i.imgur.com/3pzRj9n.png")';
  root.style.backgroundSize = "cover";
  root.style.backgroundRepeat = "no-repeat";
  root.style.backgroundPosition = "center";
}

createRoot(root!).render(
  <StrictMode>
    <App />
  </StrictMode>
);