import { FC } from "react";
import styles from "./primaryButton.module.scss";

interface Props {
  text: string;
  handleClick: () => Promise<void>;
}

const PrimaryButton: FC<Props> = ({ text, handleClick }) => {
  return (
    <button className={styles.primaryButton} onClick={handleClick}>
      {text}
    </button>
  );
};

export default PrimaryButton;
