import { 
  useState, 
  ChangeEvent, 
  FC
} from "react";
import axios from "axios";
import PrimaryButton from '../../components/buttons/PrimaryButton';
import styles from './home.module.scss';

const Home: FC = () => {
  const [url, setUrl] = useState<string>("");
  const [shortUrl, setShortUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  
  const shortUrlEndpoint = import.meta.env.VITE_SHORT_URL_ENDPOINT;

  const handleUrlChange = (event: ChangeEvent<HTMLInputElement>): void => {
    setUrl(event.target.value);
  };

  const handleSubmit = async (): Promise<void> => {
    try {
      const res = await axios.get<{ shortUrl: string }>(
        shortUrlEndpoint,
        { url }
      );

      setShortUrl(res.data.shortUrl);
      setError(null);
    } catch (err) {
      setError(
        "Error occurred while attempting to shorten URL. Please try again later."
      );
    }
  };

  return (
    <div className={styles.home}>
      Serverless URL Shortener

      <input
        type="url"
        placeholder="Enter your URL"
        value={url}
        onChange={handleUrlChange}
      />
      
      <PrimaryButton text="Shorten" handleClick={handleSubmit} />

      {shortUrl && (
        <div>
          <h3>Shortened URL:</h3>
          <a href={shortUrl} target="_blank" rel="noopener noreferrer">
            {shortUrl}
          </a>
        </div>
      )}
      
      {error && (
        <div>
          <p>{error}</p>
        </div>
      )}
    </div>
  );
};

export default Home;
