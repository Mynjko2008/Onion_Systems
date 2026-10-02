<?php
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/../helpers/resposta.php';

// Ativa exceções em vez de warnings silenciosos
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

/**
 * Devolve a conexão com o banco, abrindo-a apenas na primeira chamada.
 * A conexão é aberta sob demanda para que requisições inválidas
 * (método errado, campos vazios) sejam recusadas sem tocar no banco.
 */
function obterConexao(): mysqli
{
    static $conexao = null;

    if ($conexao instanceof mysqli) {
        return $conexao;
    }

    try {
        $conexao = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        $conexao->set_charset('utf8mb4');
    } catch (mysqli_sql_exception $e) {
        responderErroInterno($e, 'Erro ao conectar ao banco de dados.');
    }

    return $conexao;
}
