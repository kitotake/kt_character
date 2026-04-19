/**
 * Data Synchronization Service
 * Gère la persistance locale, synchronisation serveur et caching
 */

export interface SyncConfig {
  enableAutoSync: boolean;
  autoSyncInterval: number; // ms
  enableOfflineMode: boolean;
  enableIndexedDB: boolean;
  version: number;
}

export interface SyncState {
  isSyncing: boolean;
  lastSync: number | null;
  pendingChanges: number;
  isOnline: boolean;
}

class DataSyncService {
  private config: SyncConfig;
  private state: SyncState;
  private syncTimeout: ReturnType<typeof setTimeout> | null = null;
  private listeners: Map<string, Set<Function>> = new Map();

  constructor(config: Partial<SyncConfig> = {}) {
    this.config = {
      enableAutoSync: true,
      autoSyncInterval: 30000, // 30 secondes
      enableOfflineMode: true,
      enableIndexedDB: true,
      version: 1,
      ...config,
    };

    this.state = {
      isSyncing: false,
      lastSync: null,
      pendingChanges: 0,
      isOnline: typeof window !== "undefined" ? navigator.onLine : true,
    };

    this.initializeListeners();
  }

  private initializeListeners() {
    if (typeof window === "undefined") return;

    // Écouter les changements de connectivité
    window.addEventListener("online", () => this.handleOnline());
    window.addEventListener("offline", () => this.handleOffline());

    // Écouter les changements de storage d'autres onglets
    window.addEventListener("storage", (e) => this.handleStorageChange(e));
  }

  private handleOnline() {
    this.state.isOnline = true;
    this.emit("online", { isOnline: true });

    // Synchroniser immédiatement si des changements en attente
    if (this.state.pendingChanges > 0) {
      this.syncAll();
    }
  }

  private handleOffline() {
    this.state.isOnline = false;
    this.emit("offline", { isOnline: false });
  }

  private handleStorageChange(e: StorageEvent) {
    if (e.key === "character-data" || e.key === "character-presets") {
      this.emit("remote-change", { key: e.key, value: e.newValue });
    }
  }

  /**
   * Sauvegarder les données avec tracking des changements
   */
  async saveData(key: string, data: any): Promise<boolean> {
    try {
      // Sauvegarder localement
      localStorage.setItem(key, JSON.stringify(data));

      // Sauvegarder dans IndexedDB si activé
      if (this.config.enableIndexedDB) {
        await this.saveToIndexedDB(key, data);
      }

      // Incrémenter les changements en attente
      this.state.pendingChanges++;

      // Synchroniser avec serveur
      if (this.config.enableAutoSync && this.state.isOnline) {
        this.scheduleSyncall();
      }

      this.emit("data-saved", { key, data });
      return true;
    } catch (error) {
      console.error("Error saving data:", error);
      return false;
    }
  }

  /**
   * Charger les données
   */
  async loadData(key: string): Promise<any> {
    try {
      // Essayer localStorage d'abord
      const local = localStorage.getItem(key);
      if (local) {
        return JSON.parse(local);
      }

      // Essayer IndexedDB
      if (this.config.enableIndexedDB) {
        const indexed = await this.loadFromIndexedDB(key);
        if (indexed) {
          return indexed;
        }
      }

      return null;
    } catch (error) {
      console.error("Error loading data:", error);
      return null;
    }
  }

  /**
   * Synchroniser avec le serveur
   */
  async syncAll(): Promise<boolean> {
    if (this.state.isSyncing || !this.state.isOnline) {
      return false;
    }

    this.state.isSyncing = true;
    this.emit("sync-start", {});

    try {
      const characterData = localStorage.getItem("character-data");
      const presets = localStorage.getItem("character-presets");

      const resourceName = this.getResourceName();

      // Envoyer au serveur
      const response = await fetch(
        `https://${resourceName}/sync`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            characterData: characterData ? JSON.parse(characterData) : null,
            presets: presets ? JSON.parse(presets) : null,
            version: this.config.version,
            timestamp: Date.now(),
          }),
        }
      );

      if (response.ok) {
        this.state.lastSync = Date.now();
        this.state.pendingChanges = 0;
        this.emit("sync-complete", { success: true });
        return true;
      }

      throw new Error(`Sync failed: ${response.statusText}`);
    } catch (error) {
      console.error("Sync error:", error);
      this.emit("sync-error", { error });
      return false;
    } finally {
      this.state.isSyncing = false;
    }
  }

  /**
   * Planifier une synchronisation
   */
  private scheduleSyncall() {
    if (this.syncTimeout) {
      clearTimeout(this.syncTimeout);
    }

    this.syncTimeout = setTimeout(() => {
      this.syncAll();
    }, this.config.autoSyncInterval);
  }

  /**
   * Sauvegarder dans IndexedDB
   */
  private async saveToIndexedDB(key: string, data: any): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const request = indexedDB.open("CharacterCreatorDB", 1);

        request.onerror = () => reject(request.error);
        request.onsuccess = () => {
          const db = request.result;
          const transaction = db.transaction(["data"], "readwrite");
          const objectStore = transaction.objectStore("data");
          objectStore.put({ key, data, timestamp: Date.now() });

          transaction.oncomplete = () => resolve();
          transaction.onerror = () => reject(transaction.error);
        };

        request.onupgradeneeded = (event) => {
          const db = (event.target as IDBOpenDBRequest).result;
          if (!db.objectStoreNames.contains("data")) {
            db.createObjectStore("data", { keyPath: "key" });
          }
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * Charger depuis IndexedDB
   */
  private async loadFromIndexedDB(key: string): Promise<any> {
    return new Promise((resolve) => {
      try {
        const request = indexedDB.open("CharacterCreatorDB", 1);

        request.onsuccess = () => {
          const db = request.result;
          const transaction = db.transaction(["data"], "readonly");
          const objectStore = transaction.objectStore("data");
          const getRequest = objectStore.get(key);

          getRequest.onsuccess = () => {
            resolve(getRequest.result?.data || null);
          };

          getRequest.onerror = () => {
            resolve(null);
          };
        };

        request.onerror = () => resolve(null);
      } catch (error) {
        resolve(null);
      }
    });
  }

  /**
   * Obtenir le nom de la ressource
   */
  private getResourceName(): string {
    if (typeof window !== "undefined" && (window as any).GetParentResourceName) {
      return (window as any).GetParentResourceName();
    }
    return "character-creator";
  }

  /**
   * Event emitter
   */
  on(event: string, callback: Function) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
  }

  off(event: string, callback: Function) {
    this.listeners.get(event)?.delete(callback);
  }

  private emit(event: string, data: any) {
    this.listeners.get(event)?.forEach((callback) => callback(data));
  }

  /**
   * Obtenir le statut
   */
  getStatus(): SyncState {
    return { ...this.state };
  }

  /**
   * Exporter les données
   */
  async exportData(): Promise<string> {
    const characterData = localStorage.getItem("character-data");
    const presets = localStorage.getItem("character-presets");

    return JSON.stringify(
      {
        version: this.config.version,
        exportedAt: new Date().toISOString(),
        characterData: characterData ? JSON.parse(characterData) : null,
        presets: presets ? JSON.parse(presets) : null,
      },
      null,
      2
    );
  }

  /**
   * Importer les données
   */
  async importData(json: string): Promise<boolean> {
    try {
      const data = JSON.parse(json);

      if (data.characterData) {
        await this.saveData("character-data", data.characterData);
      }

      if (data.presets) {
        await this.saveData("character-presets", data.presets);
      }

      this.emit("import-complete", { success: true });
      return true;
    } catch (error) {
      console.error("Import error:", error);
      this.emit("import-error", { error });
      return false;
    }
  }

  /**
   * Effacer les données
   */
  async clearAll(): Promise<void> {
    localStorage.clear();

    if (this.config.enableIndexedDB) {
      const request = indexedDB.deleteDatabase("CharacterCreatorDB");
      request.onsuccess = () => console.log("IndexedDB cleared");
    }

    this.emit("data-cleared", {});
  }
}

// Singleton instance
export const dataSyncService = new DataSyncService({
  enableAutoSync: true,
  autoSyncInterval: 30000,
  enableOfflineMode: true,
  enableIndexedDB: true,
});

export default DataSyncService;