<?php
/**
 * Controller de contato.
 * Cuida apenas do protocolo HTTP: CORS, método, leitura do corpo da
 * requisição e montagem da resposta. As regras de negócio ficam no service.
 */
class ContatoController
{
    /**
     * Ponto de entrada: trata a requisição recebida pela API.
     */
    public function tratarRequisicao(): void
    {
        $this->aplicarCors();

        $metodo = $_SERVER['REQUEST_METHOD'] ?? '';

        // Requisição de "pré-verificação" enviada pelos navegadores em
        // chamadas de outra origem. Não carrega dados.
        if ($metodo === 'OPTIONS') {
            http_response_code(204);
            exit;
        }

        // O formulário só envia dados; nenhuma consulta é exposta ao público.
        if ($metodo !== 'POST') {
            header('Allow: POST, OPTIONS');
            responder(405, false, 'Método não permitido. Use POST.');
        }

        // Valida antes de abrir a conexão com o banco.
        $entrada = $this->lerEntrada();
        $honeypot = $entrada['url_site'] ?? '';
        // Disfarca a deteccao para o bot e evita gravar a mensagem.
        if (!is_string($honeypot) || trim($honeypot) !== '') {
            responder(200, true, 'Mensagem enviada com sucesso! Entraremos em contato em breve.');
        }

        $dados = validarContato($entrada);

        try {
            $service = new ContatoService(new Contato(obterConexao()));
            $criado  = $service->registrar($dados);

            // 201 = registro criado. 200 = repetição ignorada; a mensagem
            // é a mesma para o visitante nunca perceber a diferença.
            responder(
                $criado ? 201 : 200,
                true,
                'Mensagem enviada com sucesso! Entraremos em contato em breve.'
            );
        } catch (DomainException $e) {
            if ($e->getCode() === 429) {
                header('Retry-After: ' . (CONTATO_JANELA_LIMITE_MINUTOS * 60));
            }
            responder($e->getCode() ?: 400, false, $e->getMessage());
        } catch (Throwable $e) {
            responderErroInterno($e, 'Erro ao enviar a mensagem. Tente novamente mais tarde.');
        }
    }

    /**
     * Libera o acesso à API apenas para as origens listadas em config.php.
     * Se o front e o back estiverem no mesmo domínio, nada é necessário.
     */
    private function aplicarCors(): void
    {
        $origem = $_SERVER['HTTP_ORIGIN'] ?? '';

        if ($origem !== '' && in_array($origem, ORIGENS_PERMITIDAS, true)) {
            header('Access-Control-Allow-Origin: ' . $origem);
            header('Access-Control-Allow-Methods: POST, OPTIONS');
            header('Access-Control-Allow-Headers: Content-Type');
            header('Vary: Origin');
        }
    }

    /**
     * Lê os dados enviados pelo front-end.
     * Aceita FormData / formulário comum ($_POST) e JSON.
     */
    private function lerEntrada(): array
    {
        $tamanho = (int) ($_SERVER['CONTENT_LENGTH'] ?? 0);
        if ($tamanho > TAMANHO_MAX_REQUISICAO) {
            responder(413, false, 'Requisição muito grande.');
        }

        $tipo = $_SERVER['CONTENT_TYPE'] ?? '';

        if (stripos($tipo, 'application/json') === false) {
            return $_POST;
        }

        // Lê no máximo 1 byte além do limite, só para detectar o excesso.
        $bruto = file_get_contents('php://input', false, null, 0, TAMANHO_MAX_REQUISICAO + 1);
        if ($bruto === false || strlen($bruto) > TAMANHO_MAX_REQUISICAO) {
            responder(413, false, 'Requisição muito grande.');
        }

        $json = json_decode($bruto, true);
        if (!is_array($json)) {
            responder(400, false, 'JSON inválido.');
        }

        return $json;
    }
}
