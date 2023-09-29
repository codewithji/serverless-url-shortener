import { useState, ChangeEvent, FC } from "react";
import { Alert, Box, LinearProgress } from "@mui/material";
import axios from "axios";

import PrimaryButton from "../../components/buttons/PrimaryButton";
import CopyIconButton from "../../components/buttons/CopyIconButton";
import styles from "./home.module.scss";

const Home: FC = () => {
  const [url, setUrl] = useState<string>("");
  const [shortUrl, setShortUrl] = useState<string | null>(null);
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);

  const shortUrlEndpoint = import.meta.env.VITE_SHORT_URL_ENDPOINT;

  const handleUrlChange = (event: ChangeEvent<HTMLInputElement>): void => {
    setUrl(event.target.value);
  };

  const handleClick = async (): Promise<void> => {
    try {
      setLoading(true);
      const res = await axios.post<{ shortUrl: string }>(shortUrlEndpoint, {
        url,
      });

      setShortUrl(res.data.shortUrl);
      setError("");
    } catch (err) {
      setShortUrl("");
      setError(
        "Error occurred while attempting to shorten URL. Please try again later."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={styles.home}>
      <h1>(Not so short) URL shortener</h1>

      <div className={styles.inputContainer}>
        <input
          className={styles.urlInput}
          type="text"
          value={url}
          onChange={handleUrlChange}
          placeholder="https://example.com"
        />

        {loading && (
          <Box className={styles.loaderContainer}>
            <LinearProgress className={styles.loader} />
          </Box>
        )}

        <PrimaryButton text="Shorten" handleClick={handleClick} />
      </div>

      <div className={styles.feedbackContainer}>
        {shortUrl && (
          <Alert severity="success" className={styles.successAlert}>
            <div className={styles.successAlertContent}>
              <div>
                Here's your short URL: <span>{shortUrl}</span>
              </div>
              <CopyIconButton copyValue={shortUrl} />
            </div>
          </Alert>
        )}

        {error && <Alert severity="error">{error}</Alert>}
      </div>
    </div>
  );
};

export default Home;
