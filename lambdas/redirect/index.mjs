import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const ensureProtocol = (url) => {
  try {
    new URL(url);
    return url;
  } catch (err) {
    return `http://${url}`;
  }
}

export const handler = async (event) => {
  const id = event.pathParameters.short_url_id;

  const getCommand = new GetCommand({
    TableName: process.env.DYNAMODB_TABLE_NAME,
    Key: { id },
  });

  try {
    const res = await docClient.send(getCommand);
    const longUrl = ensureProtocol(res.Item.longUrl);

    const response = {
      statusCode: 301,
      headers: {
        Location: longUrl
      },
    };

    return response;
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({
        error:
          "An error occurred while attempting to redirect you to your URL. Please try again later.",
      }),
    };
  }
};
