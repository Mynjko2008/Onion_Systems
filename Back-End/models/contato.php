<?php
/**
 * Model de contato.
 * Único ponto que conversa com as tabelas tb_contatos e tb_status_contato.
 * Não decide regras de negócio: apenas lê e grava.
 */
class Contato
{
    public function __construct(private mysqli $conexao)
    {
    }

    /**
     * Devolve o ID de um status pelo nome, ou null se não existir.
     */
    public function buscarIdStatusPorNome(string $nome): ?int
    {
        $stmt = $this->conexao->prepare(
            "SELECT id_status_contato FROM tb_status_contato WHERE nome = ?"
        );
        $stmt->bind_param('s', $nome);
        $stmt->execute();
        $linha = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        return $linha ? (int) $linha['id_status_contato'] : null;
    }

    /**
     * Conta quantas mensagens um e-mail enviou nos últimos minutos.
     */
    public function contarRecentesPorEmail(string $email, int $minutos): int
    {
        $stmt = $this->conexao->prepare("
            SELECT COUNT(*) AS total
            FROM tb_contatos
            WHERE email = ?
              AND created_at >= (NOW() - INTERVAL ? MINUTE)
        ");
        $stmt->bind_param('si', $email, $minutos);
        $stmt->execute();
        $linha = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        return (int) $linha['total'];
    }

    /**
     * Verifica se o mesmo e-mail já enviou exatamente esta mensagem
     * nos últimos minutos.
     */
    public function existeDuplicado(string $email, string $mensagem, int $minutos): bool
    {
        $stmt = $this->conexao->prepare("
            SELECT 1
            FROM tb_contatos
            WHERE email = ?
              AND mensagem = ?
              AND created_at >= (NOW() - INTERVAL ? MINUTE)
            LIMIT 1
        ");
        $stmt->bind_param('ssi', $email, $mensagem, $minutos);
        $stmt->execute();
        $existe = (bool) $stmt->get_result()->fetch_row();
        $stmt->close();

        return $existe;
    }

    /**
     * Grava um novo contato e devolve o ID gerado.
     * A data do consentimento é sempre a do servidor (NOW()),
     * nunca um valor enviado pelo navegador.
     */
    public function inserir(array $dados): int
    {
        $stmt = $this->conexao->prepare("
            INSERT INTO tb_contatos
                (id_status_contato, nome, email, mensagem,
                 consentimento, consentimento_data, consentimento_versao)
            VALUES (?, ?, ?, ?, ?, NOW(), ?)
        ");

        $consentimento = $dados['consentimento'] ? 1 : 0;

        // i = id_status_contato, s = nome, s = email, s = mensagem,
        // i = consentimento, s = consentimento_versao
        $stmt->bind_param(
            'isssis',
            $dados['id_status_contato'],
            $dados['nome'],
            $dados['email'],
            $dados['mensagem'],
            $consentimento,
            $dados['consentimento_versao']
        );
        $stmt->execute();
        $idContato = $this->conexao->insert_id;
        $stmt->close();

        return $idContato;
    }
}
