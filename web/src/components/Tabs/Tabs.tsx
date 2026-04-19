import styles from "./Tabs.module.scss";

interface Tab {
  id: string;
  label: string;
  icon?: string;
}

interface TabsProps {
  tab: string;
  setTab: (tab: string) => void;
  tabs?: Tab[];
}

const DEFAULT_TABS: Tab[] = [
  { id: "face", label: "Visage", icon: "◉" },
  { id: "hair", label: "Cheveux", icon: "✦" },
  { id: "body", label: "Corps", icon: "◈" },
  { id: "clothes", label: "Vêtements", icon: "◇" },
];

export default function Tabs({ tab, setTab, tabs = DEFAULT_TABS }: TabsProps) {
  return (
    <div className={styles.tabs}>
      {tabs.map((t) => (
        <button
          key={t.id}
          className={`${styles.tab} ${tab === t.id ? styles.active : ""}`}
          onClick={() => setTab(t.id)}
        >
          {t.icon && <span>{t.icon}</span>}
          {t.label}
        </button>
      ))}
    </div>
  );
}