kt_character/
│   └── server/
│    ├── main.lua
│    ├── config.lua
│    ├── utils.lua
│    ├── identifiers.lua
│    ├── validator.lua
│    ├── character_create.lua
│    ├── character_load.lua
│    ├── character_skin.lua
│    ├── character_update.lua
│    └── events.lua
│
├── src/
│   ├── components/
│   │   ├── Category/
│   │   ├── ColorPicker/
│   │   ├── Comparison/              
│   │   ├── Preview/
│   │   ├── Presets/
│   │   ├── Slider/
│   │   ├── StatusBar/          
│   │   └── Tabs/
│   │
│   ├── hooks/
│   │   ├── useLocalStorage.ts
│   │   ├── usePresets.ts
│   │   └── useSyncData.ts      
│   │
│   ├── services
│   │   └── DataSyncService.ts  
│   │
│   ├── pages/
│   │   ├── Creator.tsx
│   │   └── Dashboard.tsx       
│   │
│   ├── style/
│   │   ├── _variables.sass
│   │   ├── _mixins.sass
│   │   └── global.sass
│   │
│   ├── App.tsx
│   └── main.tsx
│
├── Documentation/
│   ├── README.md
│   ├── DOCUMENTATION.md
│   ├── INTEGRATION_GUIDE.md
│   ├── TESTING.md
│   ├── CONFIGURATION.md
│   ├── CORRECTIONS_RESUMEE.md
│   └── FEATURES_V2.md          ← NEW
│
├── Configuration/
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   ├── vitest.config.ts
│   ├── .eslintrc.json
│   ├── .prettierrc.json
│   └── .gitignore
│
└── dist/
    └── (files de build)