# Arquitetura do Back-End

## Visão geral

O back-end é organizado em camadas. Cada camada tem uma responsabilidade e só conversa com a camada logo abaixo dela.

```
Navegador
    │  POST /Back-End/api/contato.php
    ▼
api/contato.php                  carrega as camadas e entrega a requisição
    ▼
controllers/contatoController    protocolo HTTP (método, CORS, corpo, resposta)
    │   └─ helpers/validacao     valida e limpa os campos
    ▼
services/contatoService          regras de negócio (consentimento, spam, status)
    ▼
models/contato                   SQL com prepared statements
    ▼
MySQL (tb_contatos, tb_status_contato)
```

Os helpers e a configuração são usados por todas as camadas:

- `helpers/resposta.php`: resposta JSON padronizada e tratamento de erro 500.
- `helpers/validacao.php`: limpeza e validação dos dados de entrada.
- `config/config.php`: constantes, fuso horário, log e tratamento global de exceções.
- `config/conexao.php`: conexão com o banco, aberta sob demanda.

## Responsabilidade de cada camada

| Camada | Faz | Não faz |
|---|---|---|
| **api/** | Carrega os arquivos e chama o controller | Nenhuma lógica |
| **controller** | CORS, método HTTP, leitura do corpo (form ou JSON), traduz exceções em códigos HTTP | Regras de negócio, SQL |
| **service** | Decide se a mensagem pode ser gravada: consentimento, links, duplicidade, limite de envios, status inicial | Conhece HTTP ou SQL |
| **model** | Lê e grava no banco | Decide regras |
| **helpers** | Funções reutilizáveis de validação e resposta | Acessam o banco |

## Fluxo de uma mensagem de contato

1. O controller aplica o CORS e recusa métodos diferentes de `POST` (`405`).
2. Lê o corpo (`$_POST` ou JSON) e recusa corpos acima de 20 KB (`413`).
3. `validarContato()` limpa e valida nome, e-mail, mensagem e consentimento (`400`, com o nome do campo com problema).
4. **Só agora** a conexão com o banco é aberta.
5. O service aplica as regras:
   1. consentimento obrigatório;
   2. no máximo 3 links na mensagem;
   3. mensagem idêntica do mesmo e-mail nos últimos 10 minutos: ignorada como sucesso (evita duplicar por duplo clique);
   4. no máximo 3 mensagens por e-mail por hora (`429` com `Retry-After`);
   5. busca o ID do status `Novo` em `tb_status_contato`.
6. O model grava em `tb_contatos`. A data do consentimento vem do servidor (`NOW()`), nunca do navegador.
7. O controller responde `201` (gravado) ou `200` (repetição ignorada), com a mesma mensagem nos dois casos.

## Tratamento de erros

| Situação | Resposta | Log |
|---|---|---|
| Entrada inválida | `400` com a mensagem e o `campo` | Não |
| Regra de negócio violada | `400` / `429` (código da `DomainException`) | Não |
| Falha inesperada (banco fora do ar, status inicial ausente) | `500` com mensagem genérica | Sim, em `logs/erros.log` |
| Exceção não tratada em qualquer ponto | `500` genérico (handler global) | Sim |

O visitante nunca vê detalhes técnicos. O `display_errors` fica sempre desligado, porque um aviso do PHP no meio da resposta quebraria o JSON.

## Decisões de segurança

- **Prepared statements** em todas as consultas: tentativas de SQL injection são gravadas como texto comum.
- **A API pública só aceita `POST`.** Nenhuma listagem ou consulta de contatos é exposta; o gerenciamento das mensagens será feito no painel, protegido por login.
- **Validação no servidor.** A validação do JavaScript existe só para a experiência do usuário e pode ser contornada.
- **Consentimento (LGPD):** são gravados o aceite, a data (do servidor) e a versão da política (`VERSAO_CONSENTIMENTO`). Sem consentimento, nada é gravado, nem pela camada de validação nem pelo service.
- **Controle de acesso:** o `.htaccess` em `Back-End/` bloqueia tudo e o de `Back-End/api/` libera apenas os endpoints. Config, models e logs não ficam acessíveis pela web.
- **Credenciais fora do código:** via variáveis de ambiente, com padrão apenas para uso local.
- **CORS restrito:** sem `CORS_ORIGENS`, nenhuma origem externa é liberada.
- **Cabeçalhos:** `X-Content-Type-Options: nosniff` e `Cache-Control: no-store` em todas as respostas.

## Decisões de projeto

- **Conexão sob demanda.** Requisições inválidas são recusadas sem abrir conexão com o banco.
- **Duplicata tratada como sucesso.** Um duplo clique não faz o visitante ver um erro depois de a primeira requisição ter dado certo.
- **Status em tabela.** `tb_contatos` usa `id_status_contato` (FK), seguindo o padrão do restante do banco, e o status inicial é buscado pelo nome em vez de fixar um ID.
- **Sem retorno do ID.** A resposta pública não devolve o `id_contato`, para não revelar o volume de mensagens recebidas.

## Limitações conhecidas

- O limite de envios é por **e-mail**, não por IP: quem trocar de e-mail a cada envio contorna o limite. Limitar por IP exigiria guardar o IP (dado pessoal) e uma coluna nova; está fora do escopo atual. Para tráfego de abuso real, o ideal é um limitador no servidor web ou um CAPTCHA.
- O texto é gravado como o visitante digitou (sem escape de HTML). O **escape deve ser feito ao exibir** a mensagem no painel (`textContent` no JavaScript ou `htmlspecialchars` no PHP).

## Como adicionar um novo módulo (exemplo: chamados)

1. `models/chamado.php`: SQL com prepared statements.
2. `services/chamadoService.php`: regras de negócio.
3. `controllers/chamadoController.php`: HTTP.
4. `api/chamado.php`: carrega as camadas e chama o controller.
5. Validações novas em `helpers/validacao.php`.
6. Documentar o endpoint em `docs/api.md`.

Endpoints que não sejam públicos devem exigir autenticação (sessão) e verificar o perfil do usuário em `tb_usuario_perfis` antes de executar qualquer ação.
