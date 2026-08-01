// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ASSET PICKER — DONNÉES (v2 — texture + color)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import type { AssetCategory, GenderModel } from "./assetPicker.types";

const SHARED_CLOTHING: AssetCategory[] = [
  { id: "jackets",     label: "Vestes / Manteaux",  icon: "🧥", count: 121, componentId: 11, textureCount: 16 },
  { id: "torsos",      label: "Hauts du corps",      icon: "👔", count: 80,  componentId: 3,  textureCount: 16 },
  { id: "undershirts", label: "Sous-vêtements",      icon: "👕", count: 80,  componentId: 8,  textureCount: 16 },
  { id: "pants",       label: "Pantalons",           icon: "👖", count: 80,  componentId: 4,  textureCount: 16 },
  { id: "shoes",       label: "Chaussures",          icon: "👟", count: 80,  componentId: 6,  textureCount: 16 },
  { id: "bags",        label: "Sacs à dos",          icon: "🎒", count: 60,  componentId: 5,  textureCount: 8  },
  { id: "vests",       label: "Gilets / Armures",    icon: "🦺", count: 40,  componentId: 9,  textureCount: 8  },
  { id: "decals",      label: "Décals / Logos",      icon: "🔖", count: 60,  componentId: 10, textureCount: 8  },
  { id: "masks",       label: "Masques",             icon: "🎭", count: 60,  componentId: 1,  textureCount: 8  },
  { id: "necks",       label: "Colliers / Écharpes", icon: "💎", count: 60,  componentId: 7,  textureCount: 8  },
];

const SHARED_PROPS: AssetCategory[] = [
  { id: "hats",    label: "Chapeaux", icon: "🎩", count: 80, propAnchor: 0, propTextureCount: 8 },
  { id: "glasses", label: "Lunettes", icon: "🕶️",  count: 50, propAnchor: 1, propTextureCount: 4 },
  { id: "watches", label: "Montres",  icon: "⌚", count: 30, propAnchor: 6, propTextureCount: 4 },
];

const SHARED_OVERLAYS: AssetCategory[] = [
  { id: "aging",       label: "Vieillissement", icon: "🕰️",  count: 16, overlayId: 3, hasColor: false, colorType: "none" },
  { id: "complextion", label: "Teint / Peau",   icon: "💧", count: 12, overlayId: 6, hasColor: false, colorType: "none" },
  { id: "makeup",      label: "Maquillage",     icon: "✨", count: 74, overlayId: 4, hasColor: true,  colorType: "makeup" },
];

export const CATEGORIES: Record<GenderModel, AssetCategory[]> = {
  mp_f_freemode_01: [
    { id: "faces", label: "Visages",    icon: "👤", count: 92, direct: true, hasColor: false, colorType: "none" },
    { id: "hair",  label: "Coiffures", icon: "✂️",  count: 76, componentId: 2, textureCount: 1, hasColor: true, colorType: "hair" },
    ...SHARED_CLOTHING,
    ...SHARED_PROPS,
    { id: "earrings",  label: "Boucles d'oreilles", icon: "💍", count: 44, propAnchor: 2, propTextureCount: 4 },
    { id: "bracelets", label: "Bracelets",           icon: "📿", count: 22, propAnchor: 7, propTextureCount: 4 },
    ...SHARED_OVERLAYS,
    { id: "lipstick",   label: "Rouge à lèvres",  icon: "💄", count: 11, overlayId: 8, hasColor: true,  colorType: "makeup" },
    { id: "facialHair", label: "Poils / Duvet",   icon: "🪮", count: 30, overlayId: 1, hasColor: true,  colorType: "hair" },
  ],
  mp_m_freemode_01: [
    { id: "faces", label: "Visages",    icon: "👤", count: 92, direct: true, hasColor: false, colorType: "none" },
    { id: "hair",  label: "Coiffures", icon: "✂️",  count: 76, componentId: 2, textureCount: 1, hasColor: true, colorType: "hair" },
    ...SHARED_CLOTHING,
    ...SHARED_PROPS,
    ...SHARED_OVERLAYS,
    { id: "facialHair", label: "Barbe / Moustache", icon: "🧔", count: 28, overlayId: 1, hasColor: true, colorType: "hair" },
  ],
};

export const CATEGORY_GROUPS = [
  { label: "Visage",      ids: ["faces", "hair", "aging", "complextion"] },
  { label: "Vêtements",   ids: ["jackets", "torsos", "undershirts", "pants", "shoes", "bags", "vests", "decals", "masks", "necks"] },
  { label: "Accessoires", ids: ["hats", "glasses", "watches", "earrings", "bracelets"] },
  { label: "Beauté",      ids: ["makeup", "lipstick", "facialHair"] },
];

// ── Palettes GTA V ────────────────────────────────────────────────────────

export const HAIR_COLORS: string[] = [
  "#1a0a00","#2c1300","#3d1c00","#4e2500","#5c2e00","#6b3800","#7a4200","#8a4e00","#9a5a00","#aa6600",
  "#ba7200","#ca7e00","#da8a00","#e8960a","#f0a020","#f5b040","#f8c060","#fad080","#fde0a0","#fff0c0",
  "#c8a060","#b89050","#a88040","#987030","#886020","#785010","#684008","#583205","#3c1e02","#200800",
  "#c0c0c0","#a8a8a8","#909090","#787878","#606060","#484848","#303030","#181818","#080808","#000000",
  "#ff4040","#e03030","#c02020","#a01010","#800000","#ff8040","#e06020","#c04010","#a02808","#801800",
  "#40a040","#208020","#106010","#004000","#002800","#4080ff","#2060e0","#1040c0","#0820a0","#000080",
  "#c040ff","#a020e0","#8010c0","#6008a0","#400080",
];

export const MAKEUP_COLORS: string[] = [
  "#000000","#1a1a1a","#333333","#4d4d4d","#666666","#808080","#999999","#b3b3b3","#cccccc","#e6e6e6",
  "#8b0000","#a00000","#b22222","#cc0000","#dc143c","#e63946","#ff0000","#ff4444","#ff6666","#ff8888",
  "#800080","#8b008b","#9400d3","#a020f0","#b044f0","#c060ff","#d080ff","#e0a0ff","#4b0082","#6a0dad",
  "#ff69b4","#ff1493","#db7093","#c71585","#ff007f","#e75480","#de5285","#c2528a","#ad5d75","#994f6c",
  "#8b4513","#a0522d","#cd853f","#d2691e","#c0965a","#daa520","#b8860b","#ffd700","#ffa500","#ff8c00",
  "#006400","#228b22","#32cd32","#00ff00","#7cfc00","#adff2f","#00ced1","#40e0d0","#48d1cc","#00bcd4",
  "#ffffff","#f5f5f5","#dcdcdc","#d3d3d3",
];
