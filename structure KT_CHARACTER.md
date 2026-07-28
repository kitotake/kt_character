# 📁 Structure du projet KT_CHARACTER

```bash
KT_CHARACTER/
│   fxmanifest.lua
│   structure.md
│
├── client/
│   ├── appearance.lua   # Gestion apparence joueur
│   ├── camera.lua       # Caméra créateur de personnage
│   ├── main.lua         # Entry client
│   └── utils.lua        # Fonctions utilitaires client
│
├── server/
│   ├── character_create.lua   # Création personnage
│   ├── character_load.lua     # Chargement personnage
│   ├── character_skin.lua     # Gestion skin
│   ├── character_update.lua   # Mise à jour données
│   ├── config.lua             # Config serveur
│   ├── events.lua             # Events réseau
│   ├── identifiers.lua        # Identifiants joueur
│   ├── main.lua               # Entry server
│   ├── outfits.lua           # Tenues / outfits
│   ├── utils.lua              # Utilitaires serveur
│   └── validator.lua          # Validation données
│
├── shared/
│   └── config.lua            # Configuration globale
│
└── web/
    │   .gitignore
    │   eslint.config.js
    │   index.html
    │   package-lock.json
    │   package.json
    │   README.md
    │   tsconfig.app.json
    │   tsconfig.json
    │   tsconfig.node.json
    │   vite.config.ts
    │
    ├── dist/                  # Build production (à ignorer Git)
    │   ├── favicon.svg
    │   ├── icons.svg
    │   ├── index.html
    │   └── assets/
    │       ├── index-CqoA0a7O.css
    │       └── index-DDhrL2RZ.js
    │
    ├── public/
    │   ├── favicon.svg
    │   └── icons.svg
    │
    └── src/
        │   App.tsx
        │   main.tsx
        │   index.css
        │   index.css.map
        │
        ├── assets/
        │   ├── hero.png
        │   ├── react.svg
        │   └── vite.svg
        │
        ├── components/        # UI du character creator
        │   ├── Category/
        │   ├── Clothing/
        │   ├── ColorPicker/
        │   ├── Comparison/
        │   ├── FaceFeatures/
        │   ├── Field/
        │   ├── HeadOverlays/
        │   ├── Parents/
        │   ├── Presets/
        │   ├── Preview/
        │   ├── Slider/
        │   ├── StatusBar/
        │   ├── Tabs/
        │   └── Tattoos/
        │
        ├── hooks/
        │   ├── useCreator.ts
        │   ├── useLocalStorage.ts
        │   ├── usePresets.ts
        │   └── useSyncData.ts
        │
        ├── pages/
        │   ├── CharacterSelect.tsx
        │   ├── Creator.tsx
        │   ├── Dashboard.tsx
        │   ├── CharacterSelect.module.scss
        │   ├── Creator.module.scss
        │   └── Dashboard.module.scss
        │
        ├── services/
        │   └── DataSyncService.ts
        │
        ├── style/
        │   ├── global.scss
        │   ├── _mixins.scss
        │   └── _variables.scss
        │
        └── types/
            └── appearance.types.ts
```

---

## 🧠 Architecture overview

### 🎮 Client

* gestion visuelle du personnage
* caméra + preview
* sync avec NUI

---

### 🖥️ Server

* création / chargement / update personnage
* validation sécurité
* gestion identifiants + outfits

---

### 📦 Shared

* config globale serveur/client

---

### 🌐 Web (NUI React)

* Creator UI complet
* système de tabs + sliders + presets
* gestion features visage / vêtements / tatouages
* sync avec backend via `DataSyncService`

---

## ⚠️ Bonnes pratiques

* `validator.lua` = obligatoire avant toute insertion DB
* `DataSyncService.ts` = unique point de communication NUI
* séparer logique création / chargement (tu le fais déjà bien)
* éviter logique métier dans `client/utils.lua`

---

## 🚀 Améliorations possibles

* ajouter `cache.lua` côté client (optimisation apparence)
* ajouter `service layer` côté server (ex: `characterService.lua`)
* centraliser events dans `events/` (server)
* ajouter `state manager` côté web (Zustand/Redux)

---

## 🔥 Verdict

👉 Très solide, niveau **framework character creator complet**
👉 UI très riche et bien découpée
👉 Backend déjà structuré comme un vrai système RP

---
