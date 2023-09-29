import { FC } from "react";
import styles from "./footer.module.scss";

const Footer: FC = () => {
  return (
    <div className={styles.footer}>
      <a target="_blank" href="https://icons8.com/icon/11871/cloud">
        Cloud
      </a>
      {" icon by "}
      <a target="_blank" href="https://icons8.com">
        Icons8
      </a>
    </div>
  );
};

export default Footer;
