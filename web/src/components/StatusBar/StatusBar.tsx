import styles from "./StatusBar.module.sass";
import { useState, useEffect } from "react";

interface StatusBarProps {
  isSyncing?: boolean;
  lastSync?: number | null;
  pendingChanges?: number;
}

export default function StatusBar({
  isSyncing = false,
  lastSync = null,
  pendingChanges = 0,
}: StatusBarProps) {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  const formatLastSync = () => {
    if (!lastSync) return "Jamais";
    const diff = Date.now() - lastSync;
    if (diff < 60_000) return "À l'instant";
    if (diff < 3_600_000) return `${Math.floor(diff / 60_000)}min`;
    return new Date(lastSync).toLocaleTimeString("fr-FR", {
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <div className={styles.bar}>
      <div className={styles.left}>
        <div className={`${styles.dot} ${isOnline ? styles.online : styles.offline}`} />
        <span className={styles.status}>
          {isOnline ? "Connecté" : "Hors ligne"}
        </span>
        {pendingChanges > 0 && (
          <>
            <span className={styles.sep}>·</span>
            <span>{pendingChanges} en attente</span>
          </>
        )}
      </div>

      <div className={styles.right}>
        <span className={`${styles.sync} ${isSyncing ? styles.syncing : ""}`}>
          {isSyncing ? "⟳ Sync..." : `Sync: ${formatLastSync()}`}
        </span>
      </div>
    </div>
  );
}