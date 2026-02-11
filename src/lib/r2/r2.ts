import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

let s3Client: S3Client | null = null;

function getClient(): S3Client {
  if (s3Client) return s3Client;

  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;

  if (!accountId || !accessKeyId || !secretAccessKey) {
    throw new Error(
      "R2 credentials not configured. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, and R2_SECRET_ACCESS_KEY in .env.local"
    );
  }

  s3Client = new S3Client({
    region: "auto",
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId,
      secretAccessKey,
    },
  });

  return s3Client;
}

function getBucket(): string {
  const bucket = process.env.R2_BUCKET_NAME;
  if (!bucket) {
    throw new Error("R2_BUCKET_NAME is not set in .env.local");
  }
  return bucket;
}

/**
 * Build an org-scoped storage key.
 * Pattern: {orgId}/{projectId}/{subpath}/{filename}
 */
export function buildKey(
  orgId: string,
  projectId: string,
  subpath: string,
  filename: string
): string {
  return `${orgId}/${projectId}/${subpath}/${filename}`;
}

/**
 * Upload a file to R2.
 */
export async function uploadFile(
  key: string,
  body: Buffer | Uint8Array | string,
  contentType?: string
): Promise<void> {
  await getClient().send(
    new PutObjectCommand({
      Bucket: getBucket(),
      Key: key,
      Body: body,
      ContentType: contentType,
    })
  );
}

/**
 * Download a file from R2 as a Buffer.
 */
export async function downloadFile(key: string): Promise<Buffer> {
  const response = await getClient().send(
    new GetObjectCommand({
      Bucket: getBucket(),
      Key: key,
    })
  );

  const stream = response.Body;
  if (!stream) {
    throw new Error(`No body returned for key: ${key}`);
  }

  // Convert readable stream to buffer
  const chunks: Uint8Array[] = [];
  for await (const chunk of stream as AsyncIterable<Uint8Array>) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

/**
 * Generate a presigned download URL.
 * Default expiry: 1 hour (3600 seconds).
 */
export async function getSignedDownloadUrl(
  key: string,
  expiresInSeconds: number = 3600
): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: getBucket(),
    Key: key,
  });

  return await getSignedUrl(getClient(), command, {
    expiresIn: expiresInSeconds,
  });
}

/**
 * Delete a file from R2.
 */
export async function deleteFile(key: string): Promise<void> {
  await getClient().send(
    new DeleteObjectCommand({
      Bucket: getBucket(),
      Key: key,
    })
  );
}

/**
 * List files under a prefix in R2.
 * Returns an array of object keys.
 */
export async function listFiles(prefix: string): Promise<string[]> {
  const response = await getClient().send(
    new ListObjectsV2Command({
      Bucket: getBucket(),
      Prefix: prefix,
    })
  );

  return (response.Contents ?? [])
    .map((obj) => obj.Key)
    .filter((key): key is string => key !== undefined);
}
