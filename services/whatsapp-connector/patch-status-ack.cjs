const fs = require('node:fs');
const path = require('node:path');

const marker = '// SLIM_TOP_LEVEL_STATUS_ACK_20261106';
const handlerAnchor = '    const makeOfflineNodeProcessor = () => {';
const mapAnchor = "            ['notification', handleNotification]";
const listenerAnchor = "    ws.on('CB:message', async (node) => {";
const handler = `    ${marker}
    const handleStatus = async (node) => {
        try {
            // A successful transport ACK, never a read receipt or a message send.
            await sendMessageAck(node);
            console.info('[Slim WhatsApp] status ACK confirmed', { offline: !!node.attrs.offline });
        } catch (error) {
            onUnexpectedError(error, 'acking status stanza');
        }
    };
`;
const listener = `    ws.on('CB:status', async (node) => {
        await processNode('status', node, 'acking status stanza', handleStatus);
    });
`;

function patchStatusAck(source) {
    const normalized = source.replace(/\r\n/g, '\n');
    const map = `${mapAnchor},\n            ['status', handleStatus]`;
    if (normalized.includes(marker)) {
        if (!normalized.includes(handler) || !normalized.includes(map) || !normalized.includes(listener)) {
            throw new Error('Status ACK patch incomplete: refusing an unverified runtime');
        }
        return normalized;
    }
    if (normalized.includes("ws.on('CB:status'") || normalized.includes("['status',")) {
        throw new Error('Upstream already handles status: review instead of registering twice');
    }
    for (const anchor of [handlerAnchor, mapAnchor, listenerAnchor]) {
        if (normalized.split(anchor).length !== 2) {
            throw new Error('Baileys status runtime changed: refusing an unverified patch');
        }
    }
    return normalized.replace(handlerAnchor, handler + handlerAnchor)
        .replace(mapAnchor, map)
        .replace(listenerAnchor, listener + listenerAnchor);
}

module.exports = { patchStatusAck };
if (require.main === module) {
    const file = process.argv[2] || '/evolution/node_modules/baileys/lib/Socket/messages-recv.js';
    const patched = patchStatusAck(fs.readFileSync(file, 'utf8'));
    // Validate the complete ESM runtime before replacing the existing file.
    const result = require('node:child_process').spawnSync(process.execPath,
        ['--input-type=module', '--check'], { input: patched, encoding: 'utf8' });
    if (result.status !== 0) throw new Error('Patched Baileys syntax invalid; runtime unchanged');
    fs.writeFileSync(file, patched);
    console.log('Verified top-level status ACK patch applied to ' + path.basename(file));
}
