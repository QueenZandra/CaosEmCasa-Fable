#!/usr/bin/env node
/**
 * Caos em Casa — relay de salas por código.
 *
 * Protocolo (espelha src/net/relay_transport.gd):
 *  - Mensagens de controle: frames de TEXTO com JSON.
 *      cliente -> servidor: {t:"create"} | {t:"join", code:"ABC123"}
 *      servidor -> cliente: {t:"created", code, id} | {t:"joined", id, peers:[...]}
 *                           {t:"peer_joined", id} | {t:"peer_left", id}
 *                           {t:"error", msg}
 *  - Pacotes do jogo: frames BINÁRIOS. Do cliente: [int32LE destino][payload]
 *    (destino 0 = broadcast). Do servidor: [int32LE origem][payload].
 *
 * Uso: node server.js [porta]   (padrão 9080)
 */
'use strict';

const { WebSocketServer } = require('ws');

const PORT = parseInt(process.argv[2] || process.env.PORT || '9080', 10);
const MAX_PLAYERS = 4;
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sem 0/O/1/I
const ROOM_TTL_MS = 4 * 60 * 60 * 1000;

/** code -> { peers: Map<id, ws>, nextId, createdAt } */
const rooms = new Map();

function makeCode() {
  for (let attempt = 0; attempt < 100; attempt++) {
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
    }
    if (!rooms.has(code)) return code;
  }
  throw new Error('could not allocate room code');
}

function sendJson(ws, obj) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(obj));
}

function frame(fromId, payload) {
  const head = Buffer.alloc(4);
  head.writeInt32LE(fromId, 0);
  return Buffer.concat([head, payload]);
}

const wss = new WebSocketServer({ port: PORT });
console.log(`[relay] Caos em Casa relay ouvindo na porta ${PORT}`);

wss.on('connection', (ws) => {
  ws.roomCode = null;
  ws.peerId = 0;
  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });

  ws.on('message', (data, isBinary) => {
    if (!isBinary) {
      handleControl(ws, data.toString());
      return;
    }
    const room = rooms.get(ws.roomCode);
    if (!room || data.length < 4) return;
    const target = data.readInt32LE(0);
    const payload = data.subarray(4);
    const out = frame(ws.peerId, payload);
    if (target === 0) {
      for (const [id, peer] of room.peers) {
        if (id !== ws.peerId && peer.readyState === peer.OPEN) peer.send(out);
      }
    } else {
      const peer = room.peers.get(target);
      if (peer && peer.readyState === peer.OPEN) peer.send(out);
    }
  });

  ws.on('close', () => {
    const room = rooms.get(ws.roomCode);
    if (!room) return;
    room.peers.delete(ws.peerId);
    for (const peer of room.peers.values()) {
      sendJson(peer, { t: 'peer_left', id: ws.peerId });
    }
    // Sem host (id 1), a sala morre.
    if (ws.peerId === 1 || room.peers.size === 0) {
      for (const peer of room.peers.values()) peer.close();
      rooms.delete(ws.roomCode);
      console.log(`[relay] sala ${ws.roomCode} encerrada`);
    }
  });

  ws.on('error', () => { /* close cuida da limpeza */ });
});

function handleControl(ws, text) {
  let msg;
  try { msg = JSON.parse(text); } catch { return; }
  if (!msg || typeof msg !== 'object') return;

  if (msg.t === 'create') {
    if (ws.roomCode) return sendJson(ws, { t: 'error', msg: 'already_in_room' });
    const code = makeCode();
    rooms.set(code, { peers: new Map([[1, ws]]), nextId: 2, createdAt: Date.now() });
    ws.roomCode = code;
    ws.peerId = 1;
    sendJson(ws, { t: 'created', code, id: 1 });
    console.log(`[relay] sala ${code} criada`);
    return;
  }

  if (msg.t === 'join') {
    if (ws.roomCode) return sendJson(ws, { t: 'error', msg: 'already_in_room' });
    const code = String(msg.code || '').trim().toUpperCase();
    const room = rooms.get(code);
    if (!room) return sendJson(ws, { t: 'error', msg: 'room_not_found' });
    if (room.peers.size >= MAX_PLAYERS) {
      return sendJson(ws, { t: 'error', msg: 'room_full' });
    }
    const id = room.nextId++;
    const existing = [...room.peers.keys()];
    room.peers.set(id, ws);
    ws.roomCode = code;
    ws.peerId = id;
    sendJson(ws, { t: 'joined', id, peers: existing });
    for (const [pid, peer] of room.peers) {
      if (pid !== id) sendJson(peer, { t: 'peer_joined', id });
    }
    console.log(`[relay] peer ${id} entrou na sala ${code}`);
    return;
  }

  sendJson(ws, { t: 'error', msg: 'unknown_message' });
}

// Ping/keepalive + limpeza de salas velhas.
setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.isAlive) { ws.terminate(); continue; }
    ws.isAlive = false;
    ws.ping();
  }
  const now = Date.now();
  for (const [code, room] of rooms) {
    if (now - room.createdAt > ROOM_TTL_MS) {
      for (const peer of room.peers.values()) peer.close();
      rooms.delete(code);
    }
  }
}, 30000);
