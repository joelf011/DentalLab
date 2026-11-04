// Lê o ficheiro .env e coloca os valores em process.env.
// (é uma função do próprio Node.js, não precisa de nenhum pacote)
try {
  process.loadEnvFile();
} catch {
  console.error('Falta o ficheiro .env. Copia o .env.example para .env e preenche-o.');
  process.exit(1);
}

// Sem segredo, qualquer pessoa conseguiria criar tokens de login falsos.
if (!process.env.JWT_SEGREDO) {
  console.error('Falta o JWT_SEGREDO no ficheiro .env. Vê no .env.example como gerar um.');
  process.exit(1);
}

// Todas as definições da aplicação ficam aqui, num só sítio.
export const config = {
  porta: Number(process.env.PORT ?? 3000),
  bd: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 5432),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  },
  jwt: {
    // Segredo para assinar os tokens de login. Está no .env e nunca vai para o Git.
    segredo: process.env.JWT_SEGREDO,
    // Durante quanto tempo um token é válido. Depois disso, é preciso fazer login outra vez.
    validade: '7d',
  },
};
