<?php
/**
 * Envia a resposta JSON padrão da API e encerra a execução.
 * Formato: { "sucesso": bool, "mensagem": string, ...extras }
 */
function responder(int $status, bool $sucesso, string $mensagem, array $extras = []): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=UTF-8');

    // Impede o navegador de "adivinhar" o tipo do conteúdo
    // e evita que a resposta fique guardada em cache.
    header('X-Content-Type-Options: nosniff');
    header('Cache-Control: no-store');

    echo json_encode(
        array_merge(
            ['sucesso' => $sucesso, 'mensagem' => $mensagem],
            $extras
        ),
        JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE
    );
    exit;
}

/**
 * Registra o erro no log e devolve uma resposta 500 genérica.
 * O detalhe técnico fica apenas no log; o visitante nunca o vê.
 */
function responderErroInterno(Throwable $e, string $mensagem): void
{
    error_log(sprintf(
        '[%s] %s em %s:%d',
        get_class($e),
        $e->getMessage(),
        $e->getFile(),
        $e->getLine()
    ));

    responder(500, false, $mensagem);
}
