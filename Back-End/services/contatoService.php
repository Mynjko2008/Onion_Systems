<?php
/**
 * Service de contato.
 * Concentra as regras de negócio do formulário público: consentimento,
 * proteção contra spam e definição do status inicial.
 *
 * Regras recusadas lançam DomainException, cujo código é o status HTTP
 * que o controller deve devolver. Falhas inesperadas (banco fora do ar,
 * status inicial inexistente) sobem como outras exceções e viram erro 500.
 */
class ContatoService
{
    public function __construct(private Contato $contato)
    {
    }

    /**
     * Registra uma mensagem de contato.
     * Devolve true quando um novo registro foi criado e false quando a
     * mensagem era uma repetição recente e foi ignorada.
     *
     * @throws DomainException quando uma regra de negócio é violada
     */
    public function registrar(array $dados): bool
    {
        // Última barreira: nunca grava dados sem o consentimento do visitante.
        // O controller já valida isso, mas a regra pertence a esta camada.
        if (($dados['consentimento'] ?? false) !== true) {
            throw new DomainException(
                'Você precisa concordar com a política de privacidade para enviar a mensagem.',
                400
            );
        }

        // Mensagens com muitos links costumam ser spam.
        if ($this->contarLinks($dados['mensagem']) > CONTATO_MAX_LINKS) {
            throw new DomainException(
                'A mensagem contém links demais. Remova alguns e tente novamente.',
                400
            );
        }

        // Repetição da mesma mensagem (ex.: duplo clique) é tratada como
        // sucesso, sem gravar de novo. Assim o visitante nunca vê um erro
        // depois de ter enviado a mensagem com êxito.
        if ($this->contato->existeDuplicado(
            $dados['email'],
            $dados['mensagem'],
            CONTATO_JANELA_DUPLICADO_MINUTOS
        )) {
            return false;
        }

        // Limite de mensagens por e-mail dentro da janela configurada.
        $recentes = $this->contato->contarRecentesPorEmail(
            $dados['email'],
            CONTATO_JANELA_LIMITE_MINUTOS
        );
        if ($recentes >= CONTATO_MAX_ENVIOS_POR_EMAIL) {
            throw new DomainException(
                'Você já enviou várias mensagens recentemente. Aguarde um pouco antes de tentar novamente.',
                429
            );
        }

        // Todo contato novo entra com o status inicial (Novo).
        $idStatus = $this->contato->buscarIdStatusPorNome(STATUS_CONTATO_INICIAL);
        if ($idStatus === null) {
            throw new RuntimeException(
                'Status inicial de contato não encontrado: ' . STATUS_CONTATO_INICIAL
            );
        }

        $this->contato->inserir([
            'id_status_contato'    => $idStatus,
            'nome'                 => $dados['nome'],
            'email'                => $dados['email'],
            'mensagem'             => $dados['mensagem'],
            'consentimento'        => true,
            'consentimento_versao' => VERSAO_CONSENTIMENTO,
        ]);

        return true;
    }

    /**
     * Conta quantos links (http://, https:// ou www.) existem no texto.
     */
    private function contarLinks(string $texto): int
    {
        return (int) preg_match_all('~(?:https?://|www\.)~i', $texto);
    }
}
