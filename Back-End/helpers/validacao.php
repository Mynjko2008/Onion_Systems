<?php
/**
 * Limpa um texto recebido do visitante.
 * - Rejeita texto com codificação inválida (devolve vazio).
 * - Remove caracteres de controle invisíveis.
 * - Em campos de linha única remove também quebras de linha e tabulações.
 * - Remove espaços do início e do fim.
 */
function limparTexto(string $valor, bool $multilinha = false): string
{
    if (!mb_check_encoding($valor, 'UTF-8')) {
        return '';
    }

    // Padroniza as quebras de linha antes de limpar
    $valor = str_replace(["\r\n", "\r"], "\n", $valor);

    // \p{Cc} = caracteres de controle.
    // No modo multilinha, \n e \t continuam permitidos.
    $padrao = $multilinha ? '/[^\P{Cc}\n\t]/u' : '/\p{Cc}/u';

    return trim(preg_replace($padrao, '', $valor) ?? '');
}

/**
 * Lê um campo de texto da entrada. Se não for string, devolve vazio.
 */
function lerTexto(array $entrada, string $campo, bool $multilinha = false): string
{
    $valor = $entrada[$campo] ?? '';
    return is_string($valor) ? limparTexto($valor, $multilinha) : '';
}

/**
 * Valida o formato do e-mail e o tamanho máximo aceito pelo banco.
 */
function emailValido(string $email): bool
{
    return mb_strlen($email) <= EMAIL_MAX
        && filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

/**
 * Interpreta o campo de consentimento.
 * O checkbox de um FormData chega como "on"; em JSON pode chegar como true.
 */
function consentimentoAceito(mixed $valor): bool
{
    if (is_string($valor)) {
        $valor = strtolower(trim($valor));
    }

    return in_array($valor, [true, 1, '1', 'on', 'true'], true);
}

/**
 * Valida os campos do formulário de contato. Devolve array com os valores
 * já tratados ou chama responder() em caso de erro.
 * Nas respostas 400, o campo "campo" indica qual input deve ser destacado.
 */
function validarContato(array $entrada): array
{
    $nome          = lerTexto($entrada, 'nome');
    $email         = mb_strtolower(lerTexto($entrada, 'email'));
    $mensagem      = lerTexto($entrada, 'mensagem', true);
    $consentimento = consentimentoAceito($entrada['consentimento'] ?? false);

    if ($nome === '') {
        responder(400, false, 'Digite seu nome.', ['campo' => 'nome']);
    }
    if (mb_strlen($nome) < NOME_MIN || !preg_match('/\p{L}/u', $nome)) {
        responder(400, false, 'Nome inválido.', ['campo' => 'nome']);
    }
    if (mb_strlen($nome) > NOME_MAX) {
        responder(400, false, 'O nome deve ter no máximo ' . NOME_MAX . ' caracteres.', ['campo' => 'nome']);
    }

    if ($email === '') {
        responder(400, false, 'Digite seu e-mail.', ['campo' => 'email']);
    }
    if (!emailValido($email)) {
        responder(400, false, 'E-mail inválido.', ['campo' => 'email']);
    }

    if ($mensagem === '') {
        responder(400, false, 'Digite sua mensagem.', ['campo' => 'mensagem']);
    }
    if (mb_strlen($mensagem) < MENSAGEM_MIN) {
        responder(400, false, 'A mensagem deve ter pelo menos ' . MENSAGEM_MIN . ' caracteres.', ['campo' => 'mensagem']);
    }
    if (mb_strlen($mensagem) > MENSAGEM_MAX) {
        responder(400, false, 'A mensagem deve ter no máximo ' . MENSAGEM_MAX . ' caracteres.', ['campo' => 'mensagem']);
    }

    if (!$consentimento) {
        responder(400, false, 'Você precisa concordar com a política de privacidade para enviar a mensagem.', ['campo' => 'consentimento']);
    }

    return [
        'nome'          => $nome,
        'email'         => $email,
        'mensagem'      => $mensagem,
        'consentimento' => true,
    ];
}
