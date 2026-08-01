import styles from "./Slider.module.scss";

interface SliderProps {
  label: string;
  min: number;
  max: number;
  value: number;
  onChange: (value: number) => void;
  step?: number;
}

export default function Slider({ label, min, max, value, onChange, step = 1 }: SliderProps) {
  const decrement = () => onChange(Math.max(min, value - step));
  const increment = () => onChange(Math.min(max, value + step));
  const percent = ((value - min) / (max - min)) * 100;
  const trackStyle = {
    background: `linear-gradient(to right, #00d9ff ${percent}%, rgba(255,255,255,0.08) ${percent}%)`,
  };

  return (
    <div className={styles.wrapper}>
      <div className={styles.header}>
        <span className={styles.label}>{label}</span>
        <span className={styles.value}>{value}</span>
      </div>
      <div className={styles.sliderRow}>
        <button className={styles.btn} onClick={decrement} type="button">−</button>
        <input
          type="range"
          className={styles.slider}
          min={min} max={max} step={step} value={value}
          style={trackStyle}
          onChange={(e) => onChange(Number(e.target.value))}
        />
        <button className={styles.btn} onClick={increment} type="button">+</button>
      </div>
    </div>
  );
}
