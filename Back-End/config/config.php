<?php
// CONFIGURAÇÕES GERAIS DO BACK-END
// Reúne em um só lugar os valores usados pelas demais camadas.
// Valores sensíveis (banco, CORS) podem ser definidos por variáveis de
// ambiente; os valores após "?:" são apenas o padrão para uso local.

require_once __DIR__ . '/../helpers/resposta.php';

mb_internal_encoding('UTF-8');
date_default_timezone_set('America/Sao_Paulo');

// Pasta onde os erros do PHP são gravados.
define('LOGS_DIR', dirname(__DIR__) . '/logs');

if (!is_dir(LOGS_DIR)) {
    mkdir(LOGS_DIR, 0755, true);
}

// Erros nunca são exibidos na resposta (isso quebraria o JSON e vazaria
// detalhes internos). Eles são gravados em logs/erros.log.
ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', LOGS_DIR . '/erros.log');
error_reporting(E_ALL);

// Qualquer exceção não tratada vira uma resposta JSON padronizada.
set_exception_handler(function (Throwable $e): void {
    responderErroInterno($e, 'Erro interno do servidor.');
});


// BANCO DE DADOS
define('DB_HOST', getenv('DB_HOST') ?: 'localhost');
define('DB_USER', getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('DB_PASS') ?: '');
define('DB_NAME', getenv('DB_NAME') ?: 'onion_systems');


// CORS
// Lista de origens autorizadas a chamar a API a partir de outro domínio,
// separadas por vírgula. Se o front e o back ficarem no mesmo domínio,
// pode permanecer vazia.
// Exemplo: CORS_ORIGENS="https://onionsystems.com.br, https://www.onionsystems.com.br"
define(
    'ORIGENS_PERMITIDAS',
    array_values(array_filter(array_map('trim', explode(',', getenv('CORS_ORIGENS') ?: ''))))
);


// FORMULÁRIO DE CONTATO

// Nome do status aplicado a toda mensagem recém-recebida.
// Deve existir em tb_status_contato.
const STATUS_CONTATO_INICIAL = 'Novo';

// Versão da política de privacidade exibida ao visitante.
// Deve ser alterada sempre que o texto da política mudar.
const VERSAO_CONSENTIMENTO = 'v1.0';

// Limites dos campos (os máximos acompanham o tamanho das colunas do banco).
const NOME_MIN     = 2;
const NOME_MAX     = 150;
const EMAIL_MAX    = 150;
const MENSAGEM_MIN = 10;
const MENSAGEM_MAX = 2000;

// Tamanho máximo do corpo da requisição, em bytes (20 KB).
const TAMANHO_MAX_REQUISICAO = 20480;

// Proteção contra spam.
// Quantidade máxima de mensagens do mesmo e-mail dentro da janela abaixo.
const CONTATO_MAX_ENVIOS_POR_EMAIL = 3;
const CONTATO_JANELA_LIMITE_MINUTOS = 60;

// Mensagem idêntica, do mesmo e-mail, dentro desta janela é considerada
// duplicada (por exemplo, duplo clique no botão de enviar).
const CONTATO_JANELA_DUPLICADO_MINUTOS = 10;

// Quantidade máxima de links permitida dentro de uma mensagem.
const CONTATO_MAX_LINKS = 3;
