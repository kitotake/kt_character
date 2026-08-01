import { useState, useEffect, useCallback, useRef } from "react";

interface SyncState {
  isSyncing: boolean;
  lastSync: number | null;
  pendingChanges: number;
  isOnline: boolean;
}

interface UseSyncDataOptions {
  resourceName?: string;
  debounceMs?: number;
}

export function useSyncData(options: UseSyncDataOptions = {}) {
  const { debounceMs = 500 } = options;

  const [syncState, setSyncState] = useState<SyncState>({
    isSyncing: false,
    lastSync: null,
    pendingChanges: 0,
    isOnline: navigator.onLine,
  });

  const pendingRef = useRef<any>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Track online status
  useEffect(() => {
    const onOnline = () =>
      setSyncState((s) => ({ ...s, isOnline: true }));
    const onOffline = () =>
      setSyncState((s) => ({ ...s, isOnline: false }));

    window.addEventListener("online", onOnline);
    window.addEventListener("offline", onOffline);
    return () => {
      window.removeEventListener("online", onOnline);
      window.removeEventListener("offline", onOffline);
    };
  }, []);

  const getResourceName = useCallback((): string => {
    if (typeof window !== "undefined" && (window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return options.resourceName ?? "kt_character";
  }, [options.resourceName]);

  const sync = useCallback(
    async (data: any): Promise<boolean> => {
      if (!syncState.isOnline) return false;

      setSyncState((s) => ({ ...s, isSyncing: true }));

      try {
        const res = await fetch(`https://${getResourceName()}/update`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(data),
        });

        if (res.ok) {
          setSyncState((s) => ({
            ...s,
            isSyncing: false,
            lastSync: Date.now(),
            pendingChanges: 0,
          }));
          return true;
        }

        throw new Error(res.statusText);
      } catch {
        setSyncState((s) => ({ ...s, isSyncing: false }));
        return false;
      }
    },
    [syncState.isOnline, getResourceName]
  );

  const debouncedSync = useCallback(
    (data: any) => {
      pendingRef.current = data;
      setSyncState((s) => ({ ...s, pendingChanges: s.pendingChanges + 1 }));

      if (timerRef.current) clearTimeout(timerRef.current);
      timerRef.current = setTimeout(() => {
        if (pendingRef.current) {
          sync(pendingRef.current);
          pendingRef.current = null;
        }
      }, debounceMs);
    },
    [sync, debounceMs]
  );

  return {
    ...syncState,
    sync,
    debouncedSync,
  };
}