import { FC, useState } from "react";
import { IconButton } from "@mui/material";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import CheckIcon from "@mui/icons-material/Check";
import styles from "./copyIconButton.module.scss";

interface Props {
  copyValue: string;
}

const CopyIconButton: FC<Props> = ({ copyValue }) => {
  const [copied, setCopied] = useState<boolean>(false);

  const copy = (): void => {
    navigator.clipboard.writeText(copyValue);
    setCopied(true);
  };

  return (
    <IconButton
      size="small"
      color="success"
      className={styles.copyButton}
      onClick={copy}
    >
      {!copied ? (
        <ContentCopyIcon fontSize="inherit" />
      ) : (
        <CheckIcon fontSize="inherit" />
      )}
    </IconButton>
  );
};

export default CopyIconButton;