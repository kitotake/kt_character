import styles from "./Category.module.sass";
import { ReactNode } from "react";

interface CategoryProps {
  title: string;
  icon?: string;
  children: ReactNode;
}

export default function Category({ title, icon, children }: CategoryProps) {
  return (
    <div className={styles.section}>
      <div className={styles.header}>
        {icon && <span className={styles.icon}>{icon}</span>}
        <span className={styles.title}>{title}</span>
      </div>
      <div className={styles.content}>{children}</div>
    </div>
  );
}