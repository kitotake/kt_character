export type GenderModel = "mp_m_freemode_01" | "mp_f_freemode_01";

export interface HeadBlend {
  shapeFirst: number; shapeSecond: number; shapeMix: number;
  skinFirst: number;  skinSecond: number;  skinMix: number;
}

export const FACE_FEATURE_LABELS: Record<number, string> = {
  0:"Largeur nez",1:"Hauteur pointe nez",2:"Longueur pointe nez",3:"Hauteur os nez",
  4:"Abaissement pointe nez",5:"Torsion os nez",6:"Hauteur sourcils",7:"Profondeur sourcils",
  8:"Hauteur pommettes",9:"Largeur pommettes",10:"Largeur joues",11:"Ouverture yeux",
  12:"Épaisseur lèvres",13:"Largeur mâchoire",14:"Longueur mâchoire",15:"Longueur menton",
  16:"Hauteur menton",17:"Largeur menton",18:"Taille fossette menton",19:"Épaisseur cou",
};

export type FaceFeatures = number[];

export interface HeadOverlay {
  index: number; opacity: number; firstColor: number; secondColor: number;
}

export type HeadOverlays = Record<number, HeadOverlay>;

export interface OverlayDef {
  id: number; name: string; maxIndex: number; hasColor: boolean; colorType: 0 | 1 | 2;
}

export const OVERLAY_DEFS: OverlayDef[] = [
  { id:0,  name:"Imperfections",         maxIndex:23, hasColor:false, colorType:0 },
  { id:1,  name:"Barbe",                 maxIndex:28, hasColor:true,  colorType:1 },
  { id:2,  name:"Sourcils",              maxIndex:33, hasColor:true,  colorType:1 },
  { id:3,  name:"Vieillissement",        maxIndex:14, hasColor:false, colorType:0 },
  { id:4,  name:"Maquillage",            maxIndex:74, hasColor:true,  colorType:2 },
  { id:5,  name:"Blush",                 maxIndex:6,  hasColor:true,  colorType:2 },
  { id:6,  name:"Teint",                 maxIndex:11, hasColor:false, colorType:0 },
  { id:7,  name:"Dommages solaires",     maxIndex:10, hasColor:false, colorType:0 },
  { id:8,  name:"Rouge à lèvres",        maxIndex:9,  hasColor:true,  colorType:2 },
  { id:9,  name:"Taches",                maxIndex:17, hasColor:false, colorType:0 },
  { id:10, name:"Poils thorax",          maxIndex:16, hasColor:true,  colorType:1 },
  { id:11, name:"Imperfections corps",   maxIndex:11, hasColor:false, colorType:0 },
  { id:12, name:"Imperfections corps+",  maxIndex:1,  hasColor:false, colorType:0 },
];

export interface HairData { style: number; color: number; highlight: number; }

export interface ClothingComponent { drawable: number; texture: number; palette: number; }

export interface ComponentDef { id: number; name: string; icon: string; }

export const COMPONENT_DEFS: ComponentDef[] = [
  { id:1,  name:"Masques",         icon:"🎭" },
  { id:3,  name:"Haut du corps",   icon:"👔" },
  { id:4,  name:"Pantalons",       icon:"👖" },
  { id:5,  name:"Sacs",            icon:"🎒" },
  { id:6,  name:"Chaussures",      icon:"👟" },
  { id:7,  name:"Accessoires",     icon:"🧣" },
  { id:8,  name:"Sous-vêtement",   icon:"👕" },
  { id:9,  name:"Gilet / Armure",  icon:"🦺" },
  { id:10, name:"Décals / Logos",  icon:"🔖" },
  { id:11, name:"Veste / Manteau", icon:"🧥" },
];

export type ClothingComponents = Record<number, ClothingComponent>;

export interface Prop { propIndex: number; propTextureIndex: number; }

export interface PropDef { anchor: number; name: string; icon: string; }

export const PROP_DEFS: PropDef[] = [
  { anchor:0, name:"Chapeaux",  icon:"🎩" },
  { anchor:1, name:"Lunettes",  icon:"🕶️"  },
  { anchor:2, name:"Oreilles",  icon:"💎" },
  { anchor:6, name:"Montres",   icon:"⌚" },
  { anchor:7, name:"Bracelets", icon:"📿" },
];

export type Props = Record<number, Prop>;

export type TattooZone = "head"|"torso"|"left_arm"|"right_arm"|"left_leg"|"right_leg";

export interface Tattoo {
  id: string; zone: TattooZone;
  collection: string; overlay: string; label: string;
}

export const TATTOO_ZONE_LABELS: Record<TattooZone, string> = {
  head:"Tête", torso:"Torse", left_arm:"Bras gauche",
  right_arm:"Bras droit", left_leg:"Jambe gauche", right_leg:"Jambe droite",
};

export const TATTOO_ZONE_ICONS: Record<TattooZone, string> = {
  head:"💀", torso:"🫀", left_arm:"💪", right_arm:"💪", left_leg:"🦵", right_leg:"🦵",
};

export interface FullAppearance {
  gender: GenderModel; headBlend: HeadBlend; faceFeatures: FaceFeatures;
  headOverlays: HeadOverlays; hair: HairData; components: ClothingComponents;
  props: Props; tattoos: Tattoo[];
}

export const DEFAULT_HEAD_BLEND: HeadBlend = {
  shapeFirst:0, shapeSecond:0, shapeMix:0.5,
  skinFirst:0,  skinSecond:0,  skinMix:0.5,
};

export const DEFAULT_FACE_FEATURES: FaceFeatures = new Array(20).fill(0.0);

export const DEFAULT_HEAD_OVERLAYS: HeadOverlays = Object.fromEntries(
  OVERLAY_DEFS.map((o) => [o.id, { index:0, opacity:1.0, firstColor:0, secondColor:0 }])
);

export const DEFAULT_COMPONENTS: ClothingComponents = Object.fromEntries(
  COMPONENT_DEFS.map((c) => [c.id, { drawable:0, texture:0, palette:0 }])
);

export const DEFAULT_PROPS: Props = Object.fromEntries(
  PROP_DEFS.map((p) => [p.anchor, { propIndex:-1, propTextureIndex:0 }])
);
