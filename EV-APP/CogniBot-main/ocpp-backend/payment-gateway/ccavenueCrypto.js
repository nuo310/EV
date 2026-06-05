/**
 * ============================================
 * CCAvenue AES-128-CBC Encryption / Decryption
 * ============================================
 *
 * CCAvenue requires all request parameters to be encrypted
 * with the merchant's Working Key using AES-128-CBC.
 *
 * Key derivation:
 *   MD5(workingKey) → 16-byte (128-bit) symmetric key
 *
 * IV (Initialization Vector):
 *   Fixed byte sequence 0x00–0x0F as mandated by CCAvenue.
 *
 * Data format:
 *   Input  → URL-encoded query string  (key1=val1&key2=val2)
 *   Output → hex-encoded cipher text
 */

const crypto = require("crypto");

// Fixed IV required by CCAvenue
const IV = Buffer.from([
  0x00, 0x01, 0x02, 0x03,
  0x04, 0x05, 0x06, 0x07,
  0x08, 0x09, 0x0a, 0x0b,
  0x0c, 0x0d, 0x0e, 0x0f,
]);

/**
 * Derive the 16-byte AES key from the CCAvenue Working Key.
 * @param {string} workingKey – The Working Key provided by CCAvenue
 * @returns {Buffer} 16-byte MD5 digest
 */
function deriveKey(workingKey) {
  return crypto.createHash("md5").update(workingKey).digest();
}

/**
 * Encrypt a plain-text query string for CCAvenue.
 *
 * @param {string} plainText – URL-encoded query string
 * @param {string} workingKey – CCAvenue Working Key
 * @returns {string} hex-encoded encrypted string (encRequest)
 */
function encrypt(plainText, workingKey) {
  const key = deriveKey(workingKey);
  const cipher = crypto.createCipheriv("aes-128-cbc", key, IV);
  let encrypted = cipher.update(plainText, "utf8", "hex");
  encrypted += cipher.final("hex");
  return encrypted;
}

/**
 * Decrypt a hex-encoded response string from CCAvenue.
 *
 * @param {string} encryptedText – hex-encoded cipher text (encResp)
 * @param {string} workingKey – CCAvenue Working Key
 * @returns {string} decrypted plain-text query string
 */
function decrypt(encryptedText, workingKey) {
  const key = deriveKey(workingKey);
  const decipher = crypto.createDecipheriv("aes-128-cbc", key, IV);
  let decrypted = decipher.update(encryptedText, "hex", "utf8");
  decrypted += decipher.final("utf8");
  return decrypted;
}

/**
 * Convert an object to a URL-encoded query string.
 *
 * @param {Object} params – key-value pairs
 * @returns {string} query string (e.g. "key1=val1&key2=val2")
 */
function toQueryString(params) {
  return Object.entries(params)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v ?? "")}`)
    .join("&");
}

/**
 * Parse a URL-encoded query string back into an object.
 *
 * @param {string} queryString – plain-text query string
 * @returns {Object} parsed key-value pairs
 */
function parseQueryString(queryString) {
  const result = {};
  queryString.split("&").forEach((pair) => {
    const [key, ...rest] = pair.split("=");
    if (key) {
      result[decodeURIComponent(key)] = decodeURIComponent(rest.join("="));
    }
  });
  return result;
}

module.exports = {
  encrypt,
  decrypt,
  toQueryString,
  parseQueryString,
};
