import styles from "./ExportAdvanced.module.sass";
import { useState } from "react";
import { Download, Copy, CheckCircle2 } from "lucide-react";

interface ExportAdvancedProps {
  data: any;
  presets: any[];
  onClose: () => void;
}

export default function ExportAdvanced({
  data,
  presets,
  onClose,
}: ExportAdvancedProps) {
  const [exportFormat, setExportFormat] = useState<"json" | "csv" | "code">(
    "json"
  );
  const [copied, setCopied] = useState(false);

  // Generate export data
  const generateJSON = () => JSON.stringify(presets, null, 2);

  const generateCSV = () => {
    const headers = ["ID", "Name", "Hair", "Beard", "HairColor", "CreatedAt"];
    const rows = presets.map((p) => [
      p.id,
      p.name,
      p.data.hair,
      p.data.beard,
      p.data.hairColor,
      new Date(p.createdAt).toLocaleDateString(),
    ]);

    return (
      [headers, ...rows].map((row) => row.map((cell) => `"${cell}"`).join(","))
        .join("\n")
    );
  };

  const generateCode = () => {
    return `// Character Presets Export
const presets = ${JSON.stringify(presets, null, 2)};

export default presets;`;
  };

  const getExportContent = () => {
    switch (exportFormat) {
      case "csv":
        return generateCSV();
      case "code":
        return generateCode();
      default:
        return generateJSON();
    }
  };

  const getFileExtension = () => {
    switch (exportFormat) {
      case "csv":
        return "csv";
      case "code":
        return "ts";
      default:
        return "json";
    }
  };

  const handleDownload = () => {
    const content = getExportContent();
    const blob = new Blob([content], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `presets-export-${Date.now()}.${getFileExtension()}`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(getExportContent());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className={styles.overlay}>
      <div className={styles.modal}>
        <div className={styles.header}>
          <h2>Exporter les Presets</h2>
          <button className={styles.closeBtn} onClick={onClose}>
            ✕
          </button>
        </div>

        <div className={styles.content}>
          {/* Format Selection */}
          <div className={styles.formatSelect}>
            <label>Format d'export:</label>
            <div className={styles.formats}>
              {(["json", "csv", "code"] as const).map((format) => (
                <button
                  key={format}
                  className={`${styles.formatBtn} ${
                    exportFormat === format ? styles.active : ""
                  }`}
                  onClick={() => setExportFormat(format)}
                >
                  {format.toUpperCase()}
                </button>
              ))}
            </div>
          </div>

          {/* Preview */}
          <div className={styles.preview}>
            <label>Aperçu:</label>
            <pre className={styles.code}>
              <code>{getExportContent().substring(0, 500)}...</code>
            </pre>
          </div>

          {/* Stats */}
          <div className={styles.stats}>
            <p>
              <strong>{presets.length}</strong> presets à exporter
            </p>
            <p>
              <strong>{getExportContent().length}</strong> caractères
            </p>
          </div>
        </div>

        {/* Actions */}
        <div className={styles.actions}>
          <button className={styles.copyBtn} onClick={handleCopy}>
            {copied ? (
              <>
                <CheckCircle2 size={16} /> Copié!
              </>
            ) : (
              <>
                <Copy size={16} /> Copier
              </>
            )}
          </button>
          <button className={styles.downloadBtn} onClick={handleDownload}>
            <Download size={16} /> Télécharger
          </button>
          <button className={styles.cancelBtn} onClick={onClose}>
            Annuler
          </button>
        </div>
      </div>
    </div>
  );
}