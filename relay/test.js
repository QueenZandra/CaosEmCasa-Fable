// Smoke test do relay: replica exatamente o protocolo de relay_transport.gd
const WebSocket = require('ws');

const URL = 'ws://127.0.0.1:9080';
let failed = false;
const assert = (cond, msg) => {
  if (cond) console.log('  OK', msg);
  else { failed = true; console.error('  FALHOU', msg); }
};

function frame(target, payloadStr) {
  const head = Buffer.alloc(4);
  head.writeInt32LE(target, 0);
  return Buffer.concat([head, Buffer.from(payloadStr)]);
}

function parse(data) {
  return { from: data.readInt32LE(0), payload: data.subarray(4).toString() };
}

async function main() {
  // 1. Host cria sala
  const host = new WebSocket(URL);
  const hostMsgs = [];
  const clientMsgs = [];
  let code = null;

  await new Promise((res) => host.on('open', res));
  host.send(JSON.stringify({ t: 'create' }));
  const created = await new Promise((res) =>
    host.once('message', (d, bin) => res(JSON.parse(d.toString()))));
  assert(created.t === 'created' && created.id === 1, `sala criada id=1 code=${created.code}`);
  code = created.code;
  assert(/^[A-Z2-9]{6}$/.test(code), 'código com 6 caracteres válidos');

  // 2. Cliente entra com o código (minúsculas para testar normalização)
  const client = new WebSocket(URL);
  await new Promise((res) => client.on('open', res));
  client.send(JSON.stringify({ t: 'join', code: code.toLowerCase() }));
  const joinedP = new Promise((res) =>
    client.once('message', (d) => res(JSON.parse(d.toString()))));
  const peerJoinedP = new Promise((res) =>
    host.once('message', (d) => res(JSON.parse(d.toString()))));
  const joined = await joinedP;
  const peerJoined = await peerJoinedP;
  assert(joined.t === 'joined' && joined.id === 2, 'cliente entrou com id=2');
  assert(JSON.stringify(joined.peers) === '[1]', 'cliente vê peers=[1]');
  assert(peerJoined.t === 'peer_joined' && peerJoined.id === 2, 'host notificado do peer 2');

  // 3. Pacote binário cliente -> host (unicast para 1)
  const hostGotP = new Promise((res) => host.once('message', (d, isBin) => res({ d, isBin })));
  client.send(frame(1, 'input:frame'), { binary: true });
  const hostGot = await hostGotP;
  assert(hostGot.isBin, 'host recebeu frame binário');
  const p1 = parse(hostGot.d);
  assert(p1.from === 2 && p1.payload === 'input:frame', `host viu origem=2 payload="${p1.payload}"`);

  // 4. Broadcast host -> demais (target 0)
  const clientGotP = new Promise((res) => client.once('message', (d, isBin) => res({ d, isBin })));
  host.send(frame(0, 'snapshot:123'), { binary: true });
  const clientGot = await clientGotP;
  const p2 = parse(clientGot.d);
  assert(clientGot.isBin && p2.from === 1 && p2.payload === 'snapshot:123', 'broadcast do host chegou ao cliente');

  // 5. Sala inexistente
  const stranger = new WebSocket(URL);
  await new Promise((res) => stranger.on('open', res));
  stranger.send(JSON.stringify({ t: 'join', code: 'XXXXXX' }));
  const err = await new Promise((res) =>
    stranger.once('message', (d) => res(JSON.parse(d.toString()))));
  assert(err.t === 'error' && err.msg === 'room_not_found', 'sala inexistente rejeitada');
  stranger.close();

  // 6. Host sai -> sala fecha, cliente é derrubado
  const closedP = new Promise((res) => client.on('close', res));
  host.close();
  await closedP;
  assert(true, 'sala encerrada quando o host saiu');

  console.log(failed ? '\nRELAY: FALHOU' : '\nRELAY: TUDO OK');
  process.exit(failed ? 1 : 0);
}

main().catch((e) => { console.error(e); process.exit(1); });
