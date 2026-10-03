# API

Base local: `http://localhost/Onion-Systems/Back-End/api/`

Todas as respostas são JSON (UTF-8) no formato:

```json
{ "sucesso": true, "mensagem": "texto", "...extras": "..." }
```

## POST /contato.php

Registra uma mensagem enviada pelo formulário de contato do site. Público, sem autenticação.

### Requisição

Aceita `multipart/form-data` (FormData), `application/x-www-form-urlencoded` ou `application/json`. Corpo máximo: 20 KB.

| Campo | Tipo | Obrigatório | Regras |
|---|---|---|---|
| `nome` | texto | sim | 2 a 150 caracteres, com pelo menos uma letra |
| `email` | texto | sim | E-mail válido, até 150 caracteres. Gravado em minúsculas |
| `mensagem` | texto | sim | 10 a 2000 caracteres, no máximo 3 links |
| `consentimento` | booleano | sim | Deve ser aceito: `on`, `1`, `true` ou `true` em JSON |
| `url_site` | texto | não | Campo reservado ao honeypot; deve permanecer vazio. Se preenchido, a API responde com sucesso sem gravar a mensagem |

Os textos são limpos antes da validação: espaços das pontas e caracteres de controle invisíveis são removidos.
A data do consentimento e a versão da política são definidas pelo servidor.

### Respostas

| Status | Quando | Corpo |
|---|---|---|
| `201 Created` | Mensagem gravada | `sucesso: true` |
| `200 OK` | Mensagem idêntica enviada pelo mesmo e-mail nos últimos 10 minutos: ignorada, sem duplicar | `sucesso: true` (mesma mensagem do 201) |
| `400 Bad Request` | Campo inválido, consentimento ausente, links demais ou JSON inválido | `sucesso: false`, `mensagem` e, nos erros de campo, `campo` |
| `405 Method Not Allowed` | Método diferente de `POST` | cabeçalho `Allow: POST, OPTIONS` |
| `413 Request Entity Too Large` | Corpo acima de 20 KB | |
| `429 Too Many Requests` | Mais de 3 mensagens do mesmo e-mail em 1 hora | cabeçalho `Retry-After: 3600` |
| `500 Internal Server Error` | Falha interna. O detalhe fica em `Back-End/logs/erros.log` | mensagem genérica |

`OPTIONS` responde `204` (pré-verificação de CORS).

O valor de `campo` nos erros `400` é o `name` do input a destacar: `nome`, `email`, `mensagem` ou `consentimento`.
O campo `url_site` é reservado ao honeypot do formulário e não deve ser removido nem preenchido pelo front-end.

### Exemplos

Sucesso:

```http
HTTP/1.1 201 Created

{"sucesso":true,"mensagem":"Mensagem enviada com sucesso! Entraremos em contato em breve."}
```

Erro de validação:

```http
HTTP/1.1 400 Bad Request

{"sucesso":false,"mensagem":"E-mail inválido.","campo":"email"}
```

cURL (formulário):

```bash
curl -i -X POST http://localhost/Onion-Systems/Back-End/api/contato.php \
  -d "nome=Maria Silva" \
  -d "email=maria@empresa.com" \
  -d "mensagem=Gostaria de um orçamento de sistema web." \
  -d "consentimento=on"
```

cURL (JSON):

```bash
curl -i -X POST http://localhost/Onion-Systems/Back-End/api/contato.php \
  -H "Content-Type: application/json" \
  -d '{"nome":"João Ávila","email":"joao@empresa.com","mensagem":"Preciso de suporte em banco de dados.","consentimento":true}'
```

## Integração no Front-End

O formulário do `home.html` (`#formContato`) é tratado por `Front-End/js/contato.js`, carregado depois do `home.js`. O script:

1. Valida os campos no navegador com as mesmas regras do back-end (só para avisar mais rápido; o servidor sempre valida de novo).
2. Envia os dados com `fetch` e `FormData`, que já manda o checkbox como `on`.
3. Impede envios repetidos enquanto a requisição está em andamento (o botão fica desabilitado) e cancela a espera após 15 segundos.
4. Mostra a mensagem do servidor em `#formStatus` (classes `sucesso` e `erro`).
5. Em erros de campo, usa o `campo` da resposta para marcar o input com `aria-invalid="true"` e levar o foco até ele.
6. Se o servidor devolver algo que não seja JSON, ou a conexão falhar, mostra uma mensagem genérica.

O endereço da API fica na constante `URL_API_CONTATO`, no topo do arquivo. O valor `../Back-End/api/contato.php` vale quando o `home.html` está em `Front-End/`; em produção, ajuste para a URL real. Os limites dos campos (`LIMITES`) devem acompanhar `Back-End/config/config.php`, e os atributos `maxlength` do HTML já seguem esses valores.

## Endpoints futuros

Contratos, chamados, usuários e a gestão dos contatos recebidos serão expostos apenas ao painel interno e exigirão autenticação. Eles não fazem parte da API pública.
