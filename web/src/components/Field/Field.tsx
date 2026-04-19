import styles from "./Field.module.sass";

type FieldType = "text" | "date" | "select" | "readonly";

interface SelectOption {
  value: string;
  label: string;
}

interface FieldProps {
  label: string;
  type?: FieldType;
  value: string;
  onChange?: (value: string) => void;
  placeholder?: string;
  hint?: string;
  error?: string;
  required?: boolean;
  options?: SelectOption[]; // for type="select"
  disabled?: boolean;
}

export default function Field({
  label,
  type = "text",
  value,
  onChange,
  placeholder,
  hint,
  error,
  required,
  options = [],
  disabled,
}: FieldProps) {
  return (
    <div className={styles.wrapper}>
      <label className={styles.label}>
        {label}
        {required && <span className={styles.required}>*</span>}
      </label>

      {type === "readonly" ? (
        <div className={styles.readonlyValue}>{value || "—"}</div>
      ) : type === "select" ? (
        <select
          className={styles.select}
          value={value}
          onChange={(e) => onChange?.(e.target.value)}
          disabled={disabled}
        >
          {options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      ) : (
        <input
          className={styles.input}
          type={type}
          value={value}
          placeholder={placeholder}
          disabled={disabled}
          onChange={(e) => onChange?.(e.target.value)}
        />
      )}

      {hint && !error && <span className={styles.hint}>{hint}</span>}
      {error && <span className={styles.error}>{error}</span>}
    </div>
  );
}