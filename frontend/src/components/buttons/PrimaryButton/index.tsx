import { FC, useEffect } from "react";
import styles from "./primaryButton.module.scss";

interface Props {
  text: string;
  handleClick: () => Promise<void>;
}

const PrimaryButton: FC<Props> = ({ text, handleClick }) => {
  useEffect(() => {
    const handleEnter = (e: KeyboardEvent) => {
      if (e.key === "Enter") {
        return handleClick();
      }
    };

    window.addEventListener("keydown", handleEnter);

    return () => {
      window.removeEventListener("keydown", handleEnter);
    };
  }, []);

  return (
    <button className={styles.primaryButton} onClick={handleClick}>
      {text}
    </button>
  );
};

export default PrimaryButton;
