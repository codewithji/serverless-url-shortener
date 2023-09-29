import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";
import { randomBytes } from "crypto";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const handler = async (event) => {
  const longUrl = JSON.parse(event.body).url;

  if (!longUrl) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "URL is required" }),
    };
  }

  const urlId = randomBytes(4).toString("hex");
  const shortUrl = `${process.env.BASE_URL}/${urlId}`;

  const putCommand = new PutCommand({
    TableName: process.env.DYNAMODB_TABLE_NAME,
    Item: {
      id: urlId,
      longUrl: longUrl,
      shortUrl: shortUrl,
    },
  });

  try {
    await docClient.send(putCommand);
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({
      error: "Error occurred while attempting to shorten URL"
      }),
    };
  }

  return {
    statusCode: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ shortUrl }),
  };
};
