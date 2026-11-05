const fs = require('node:fs');
const path = require('node:path');

const original = `                    await nodeProcessor(node);
                }
                isProcessing = false;`;
const replacement = `                    try {
                        await nodeProcessor(node);
                    } catch (error) {
                        // A failed node must not freeze every subsequent offline message.
                        // Keep the provider's existing error reporting and ACK policy.
                        onUnexpectedError(error, 'processing offline node');
                    }
                }
                isProcessing = false;`;

function patchOfflineQueue(source) {
  const normalized = source.replace(/\r\n/g, '\n');
  if (normalized.includes(replacement)) return normalized;
  if (normalized.split(original).length !== 2) {
    throw new Error('Baileys offline queue changed: refusing an unverified patch');
  }
  return normalized.replace(original, replacement);
}

module.exports = { patchOfflineQueue };
if (require.main === module) {
  const file = process.argv[2] || '/evolution/node_modules/baileys/lib/Socket/messages-recv.js';
  const source = fs.readFileSync(file, 'utf8');
  fs.writeFileSync(file, patchOfflineQueue(source));
  console.log('Verified offline queue isolation patch applied to ' + path.basename(file));
}
