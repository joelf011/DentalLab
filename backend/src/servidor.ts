import { construirApp } from './app.ts';
import { configuracao } from './configuracao.ts';

// Arranca a API (o que a API faz está em app.ts).
const app = construirApp();

// host '0.0.0.0' = aceita pedidos de qualquer rede do PC, e não só do próprio PC (localhost).
// É o que permite ao emulador Android e aos telemóveis na mesma rede Wi-Fi chegarem à API.
// Ao arrancar, o terminal mostra os endereços: o que não é 127.0.0.1 é o que se usa no telemóvel.
await app.listen({ port: configuracao.porta, host: '0.0.0.0' });
