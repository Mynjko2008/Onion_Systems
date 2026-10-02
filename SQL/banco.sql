CREATE DATABASE IF NOT EXISTS onion_systems
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE onion_systems;

-- Remove primeiro as views, pois elas dependem das tabelas.
-- Em seguida, remove as tabelas filhas antes das tabelas principais,
-- evitando conflitos com as chaves estrangeiras.

DROP VIEW IF EXISTS vw_chamados_completos;
DROP VIEW IF EXISTS vw_contratos_completos;

DROP TABLE IF EXISTS tb_logs_auditoria;
DROP TABLE IF EXISTS tb_interacoes_chamado;
DROP TABLE IF EXISTS tb_chamados;
DROP TABLE IF EXISTS tb_contratos;
DROP TABLE IF EXISTS tb_contatos;
DROP TABLE IF EXISTS tb_usuario_perfis;

DROP TABLE IF EXISTS tb_status_contato;
DROP TABLE IF EXISTS tb_prioridades;
DROP TABLE IF EXISTS tb_categorias;
DROP TABLE IF EXISTS tb_status_chamado;
DROP TABLE IF EXISTS tb_status_contrato;
DROP TABLE IF EXISTS tb_tipos_contrato;

DROP TABLE IF EXISTS tb_empresas;
DROP TABLE IF EXISTS tb_perfis;
DROP TABLE IF EXISTS tb_usuarios;


-- TABELAS DE CADASTRO
-- Contêm as informações básicas utilizadas pelas demais partes do sistema.
-- São criadas primeiro porque outras tabelas dependem delas.

CREATE TABLE tb_usuarios (
    -- Identificador único de cada usuário.
    id_usuario INT UNSIGNED AUTO_INCREMENT,

    -- Nome completo do usuário cadastrado.
    nome VARCHAR(150) NOT NULL,

    -- E-mail utilizado para identificação do usuário.
    -- Não permite que dois usuários utilizem o mesmo endereço.
    -- A validação do formato do e-mail deve ser feita pela aplicação.
    email VARCHAR(150) NOT NULL,

    -- Armazena o hash da senha gerado pela aplicação.
    -- Nunca deve ser armazenada a senha em texto puro.
    senha VARCHAR(255) NOT NULL COMMENT 'Armazene o hash da senha, nunca o valor em texto puro',

    -- Indica se o usuário está ativo para utilizar o sistema.
    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    -- Registra automaticamente quando o usuário foi cadastrado.
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Atualiza automaticamente quando os dados do usuário forem alterados.
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    -- Define o identificador principal da tabela.
    CONSTRAINT pk_tb_usuarios PRIMARY KEY (id_usuario),

    -- Garante que cada usuário possua um e-mail exclusivo.
    CONSTRAINT uq_tb_usuarios_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Armazena os perfis de acesso disponíveis no sistema.
-- Os perfis são utilizados para organizar as permissões dos usuários.

CREATE TABLE tb_perfis (
    -- Identificador único do perfil.
    id_perfil INT UNSIGNED AUTO_INCREMENT,

    -- Nome do perfil, como Administrador, Gestor ou Técnico.
    nome VARCHAR(60) NOT NULL,

    -- Explicação das funções relacionadas ao perfil.
    descricao VARCHAR(255) NULL,

    -- Permite desativar um perfil sem precisar apagá-lo.
    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_tb_perfis PRIMARY KEY (id_perfil),

    -- Não permite cadastrar dois perfis com o mesmo nome.
    CONSTRAINT uq_tb_perfis_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Armazena as empresas atendidas pela Onion Systems.
-- Essas empresas podem possuir contratos e abrir chamados no sistema.

CREATE TABLE tb_empresas (
    -- Identificador único da empresa.
    id_empresa INT UNSIGNED AUTO_INCREMENT,

    -- Nome jurídico registrado da empresa.
    razao_social VARCHAR(200) NOT NULL,

    -- Nome utilizado comercialmente pela empresa.
    nome_fantasia VARCHAR(200) NULL,

    -- CNPJ armazenado somente com os 14 dígitos.
    -- O banco confere apenas a quantidade de dígitos.
    -- A validação matemática do documento deve ser feita pela aplicação.
    cnpj CHAR(14) NOT NULL COMMENT 'Informe os 14 digitos sem pontuacao',

    email VARCHAR(150) NULL,
    telefone VARCHAR(20) NULL,

    -- Dados utilizados para armazenar o endereço da empresa.
    -- O CEP é armazenado somente com os 8 dígitos, sem hífen.
    cep CHAR(8) NULL,
    logradouro VARCHAR(200) NULL,
    numero VARCHAR(20) NULL,
    complemento VARCHAR(100) NULL,
    bairro VARCHAR(100) NULL,
    cidade VARCHAR(100) NULL,
    estado CHAR(2) NULL,

    -- Permite desativar a empresa sem apagar seu histórico.
    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    -- Data de criação do cadastro.
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Data da última alteração realizada no cadastro.
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_tb_empresas PRIMARY KEY (id_empresa),

    -- Impede o cadastro de duas empresas com o mesmo CNPJ.
    CONSTRAINT uq_tb_empresas_cnpj UNIQUE (cnpj),

    -- Garante que o CNPJ possua exatamente 14 caracteres.
    CONSTRAINT ck_tb_empresas_cnpj CHECK (CHAR_LENGTH(cnpj) = 14),

    -- Garante que o CEP, quando informado, possua exatamente 8 caracteres.
    CONSTRAINT ck_tb_empresas_cep CHECK (cep IS NULL OR CHAR_LENGTH(cep) = 8)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Define os tipos de contratos oferecidos pela empresa.
-- A tabela evita repetir os mesmos nomes diretamente em tb_contratos.

CREATE TABLE tb_tipos_contrato (
    id_tipo_contrato INT UNSIGNED AUTO_INCREMENT,

    -- Nome do tipo de contrato.
    nome VARCHAR(80) NOT NULL,

    -- Descrição complementar do tipo de contrato.
    descricao VARCHAR(255) NULL,

    -- Permite desativar um tipo sem remover contratos existentes.
    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_tb_tipos_contrato PRIMARY KEY (id_tipo_contrato),
    CONSTRAINT uq_tb_tipos_contrato_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Armazena os possíveis estados de um contrato.
-- O contrato utiliza um desses status para indicar sua situação atual.

CREATE TABLE tb_status_contrato (
    id_status_contrato INT UNSIGNED AUTO_INCREMENT,

    -- Nome do status do contrato.
    nome VARCHAR(60) NOT NULL,

    -- Explicação do significado do status.
    descricao VARCHAR(255) NULL,

    CONSTRAINT pk_tb_status_contrato PRIMARY KEY (id_status_contrato),
    CONSTRAINT uq_tb_status_contrato_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Define as categorias utilizadas para classificar os chamados.
-- A categorização facilita a organização e a busca pelos atendimentos.

CREATE TABLE tb_categorias (
    id_categoria INT UNSIGNED AUTO_INCREMENT,

    nome VARCHAR(80) NOT NULL,
    descricao VARCHAR(255) NULL,

    -- Permite desativar uma categoria sem apagar seu histórico.
    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_tb_categorias PRIMARY KEY (id_categoria),
    CONSTRAINT uq_tb_categorias_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Define os níveis de prioridade dos chamados.
-- O campo nivel permite ordenar as prioridades de forma numérica.

CREATE TABLE tb_prioridades (
    id_prioridade INT UNSIGNED AUTO_INCREMENT,

    nome VARCHAR(40) NOT NULL,

    -- Representa numericamente a prioridade.
    -- Quanto maior o valor, maior o nível de urgência.
    nivel TINYINT UNSIGNED NOT NULL,

    CONSTRAINT pk_tb_prioridades PRIMARY KEY (id_prioridade),

    -- Impede a criação de duas prioridades com o mesmo nome.
    CONSTRAINT uq_tb_prioridades_nome UNIQUE (nome),

    -- Impede que dois níveis sejam utilizados por prioridades diferentes.
    CONSTRAINT uq_tb_prioridades_nivel UNIQUE (nivel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Define os estados possíveis durante o atendimento de um chamado.

CREATE TABLE tb_status_chamado (
    id_status_chamado INT UNSIGNED AUTO_INCREMENT,

    nome VARCHAR(60) NOT NULL,
    descricao VARCHAR(255) NULL,

    CONSTRAINT pk_tb_status_chamado PRIMARY KEY (id_status_chamado),
    CONSTRAINT uq_tb_status_chamado_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Define os estados possíveis de uma mensagem recebida pelo formulário do site.
-- A tabela substitui o texto livre que existia em tb_contatos, evitando
-- variações como "Novo", "novo" e "NOVO" para o mesmo status.

CREATE TABLE tb_status_contato (
    id_status_contato INT UNSIGNED AUTO_INCREMENT,

    -- Nome do status do contato.
    nome VARCHAR(60) NOT NULL,

    -- Explicação do significado do status.
    descricao VARCHAR(255) NULL,

    CONSTRAINT pk_tb_status_contato PRIMARY KEY (id_status_contato),
    CONSTRAINT uq_tb_status_contato_nome UNIQUE (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Armazena as mensagens enviadas pelo formulário público do site.
-- O mesmo visitante pode enviar várias mensagens utilizando o mesmo e-mail.

CREATE TABLE tb_contatos (
    id_contato INT UNSIGNED AUTO_INCREMENT,

    -- Situação atual da mensagem dentro do atendimento.
    -- A aplicação deve informar o status inicial (Novo) ao registrar o contato.
    id_status_contato INT UNSIGNED NOT NULL,

    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    mensagem TEXT NOT NULL,

    -- Registra se o visitante autorizou o armazenamento dos dados enviados.
    consentimento BOOLEAN NOT NULL DEFAULT FALSE,

    -- Guarda quando e qual versão do consentimento foi apresentada.
    consentimento_data DATETIME NULL,
    consentimento_versao VARCHAR(20) NULL,

    -- Registra automaticamente quando a mensagem foi recebida.
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_tb_contatos PRIMARY KEY (id_contato),

    -- Relaciona o contato ao seu status atual.
    -- RESTRICT impede excluir um status que ainda esteja em uso.
    CONSTRAINT fk_contatos_status
        FOREIGN KEY (id_status_contato) REFERENCES tb_status_contato (id_status_contato)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- RELACIONAMENTO ENTRE USUÁRIOS E PERFIS
-- Um usuário pode possuir vários perfis e um perfil pode ser atribuído
-- a vários usuários. Por isso, esse relacionamento é do tipo N:N.
-- A tabela abaixo funciona como uma tabela associativa.

CREATE TABLE tb_usuario_perfis (
    id_usuario INT UNSIGNED NOT NULL,
    id_perfil INT UNSIGNED NOT NULL,

    -- A combinação dos dois IDs identifica o relacionamento.
    -- Assim, o mesmo perfil não pode ser associado duas vezes ao usuário.
    CONSTRAINT pk_tb_usuario_perfis PRIMARY KEY (id_usuario, id_perfil),

    -- Relaciona o registro ao usuário correspondente.
    -- CASCADE remove a associação quando o usuário é excluído.
    CONSTRAINT fk_usuario_perfis_usuario
        FOREIGN KEY (id_usuario) REFERENCES tb_usuarios (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relaciona o registro ao perfil correspondente.
    -- CASCADE remove a associação quando o perfil é excluído.
    CONSTRAINT fk_usuario_perfis_perfil
        FOREIGN KEY (id_perfil) REFERENCES tb_perfis (id_perfil)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- TABELAS PRINCIPAIS
-- Armazenam as informações centrais do sistema.
-- Seus registros utilizam chaves estrangeiras para se relacionar
-- com as tabelas de cadastro criadas anteriormente.


-- Armazena os contratos firmados entre a Onion Systems e seus clientes.

CREATE TABLE tb_contratos (
    id_contrato INT UNSIGNED AUTO_INCREMENT,

    -- Empresa que possui o contrato.
    id_empresa INT UNSIGNED NOT NULL,

    -- Usuário responsável pelo acompanhamento do contrato.
    id_responsavel INT UNSIGNED NOT NULL,

    -- Tipo do contrato cadastrado.
    id_tipo_contrato INT UNSIGNED NOT NULL,

    -- Situação atual do contrato.
    id_status_contrato INT UNSIGNED NOT NULL,

    titulo VARCHAR(200) NOT NULL,
    descricao TEXT NULL,

    -- Número utilizado para identificar o contrato.
    numero_contrato VARCHAR(50) NOT NULL,

    -- Valor financeiro do contrato.
    -- DECIMAL é utilizado para preservar a precisão de valores monetários.
    valor DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    -- Define o período de validade do contrato.
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,

    -- Quantidade de dias utilizada para alertar sobre a renovação.
    dias_alerta_renovacao SMALLINT UNSIGNED NOT NULL DEFAULT 30,

    -- Define se o contrato deve ser renovado automaticamente.
    renovacao_automatica BOOLEAN NOT NULL DEFAULT FALSE,

    observacoes TEXT NULL,

    -- Datas de criação e última alteração do registro.
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_tb_contratos PRIMARY KEY (id_contrato),

    -- Permite que uma mesma empresa possua números de contrato diferentes.
    -- A combinação empresa + número deve ser única.
    -- Esse índice também atende as consultas feitas apenas por id_empresa.
    CONSTRAINT uq_tb_contratos_empresa_numero UNIQUE (id_empresa, numero_contrato),

    -- Garante que a data de término não seja anterior à data inicial.
    CONSTRAINT ck_tb_contratos_datas CHECK (data_fim >= data_inicio),

    -- Impede que o valor do contrato seja negativo.
    CONSTRAINT ck_tb_contratos_valor CHECK (valor >= 0),

    -- Limita o alerta de renovação a um intervalo coerente (1 a 365 dias).
    CONSTRAINT ck_tb_contratos_dias_alerta CHECK (dias_alerta_renovacao BETWEEN 1 AND 365),

    -- Relaciona o contrato à empresa.
    -- RESTRICT impede excluir uma empresa que possua contratos vinculados.
    CONSTRAINT fk_contratos_empresa
        FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relaciona o contrato ao usuário responsável.
    CONSTRAINT fk_contratos_responsavel
        FOREIGN KEY (id_responsavel) REFERENCES tb_usuarios (id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relaciona o contrato ao tipo cadastrado.
    CONSTRAINT fk_contratos_tipo
        FOREIGN KEY (id_tipo_contrato) REFERENCES tb_tipos_contrato (id_tipo_contrato)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relaciona o contrato ao seu status atual.
    CONSTRAINT fk_contratos_status
        FOREIGN KEY (id_status_contrato) REFERENCES tb_status_contrato (id_status_contrato)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- Armazena os chamados técnicos registrados pelas empresas.

CREATE TABLE tb_chamados (
    id_chamado INT UNSIGNED AUTO_INCREMENT,

    -- Empresa responsável pela solicitação.
    id_empresa INT UNSIGNED NOT NULL,

    -- Usuário que realizou a abertura do chamado.
    id_usuario_abertura INT UNSIGNED NOT NULL,

    -- Usuário responsável pelo atendimento.
    -- Permanece NULL enquanto o chamado ainda não tiver responsável.
    id_usuario_responsavel INT UNSIGNED NULL COMMENT 'Nulo enquanto o chamado nao tiver responsavel',

    -- Classificação do problema ou solicitação.
    id_categoria INT UNSIGNED NOT NULL,

    -- Grau de prioridade do atendimento.
    id_prioridade INT UNSIGNED NOT NULL,

    -- Situação atual do chamado.
    id_status_chamado INT UNSIGNED NOT NULL,

    titulo VARCHAR(200) NOT NULL,
    descricao TEXT NOT NULL,

    -- Registra automaticamente a data e hora da abertura.
    data_abertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Fica NULL enquanto o chamado não tiver sido encerrado.
    data_fechamento DATETIME NULL,

    -- created_at indica quando o registro foi criado no banco.
    -- updated_at é atualizado automaticamente a cada alteração do chamado.
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_tb_chamados PRIMARY KEY (id_chamado),

    -- Impede que o chamado seja fechado antes de ter sido aberto.
    CONSTRAINT ck_chamados_data_fechamento
        CHECK (data_fechamento IS NULL OR data_fechamento >= data_abertura),

    -- Impede títulos vazios ou compostos apenas por espaços.
    -- A validação principal continua sendo feita pela aplicação.
    CONSTRAINT ck_chamados_titulo CHECK (CHAR_LENGTH(TRIM(titulo)) >= 3),

    -- Mantém o chamado vinculado à empresa solicitante.
    CONSTRAINT fk_chamados_empresa
        FOREIGN KEY (id_empresa) REFERENCES tb_empresas (id_empresa)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Mantém registrado o usuário que abriu o chamado.
    CONSTRAINT fk_chamados_usuario_abertura
        FOREIGN KEY (id_usuario_abertura) REFERENCES tb_usuarios (id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relaciona o chamado ao responsável pelo atendimento.
    -- SET NULL permite retirar o responsável sem excluir o chamado.
    CONSTRAINT fk_chamados_usuario_responsavel
        FOREIGN KEY (id_usuario_responsavel) REFERENCES tb_usuarios (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE,

    -- Relaciona o chamado à categoria correspondente.
    CONSTRAINT fk_chamados_categoria
        FOREIGN KEY (id_categoria) REFERENCES tb_categorias (id_categoria)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relaciona o chamado ao nível de prioridade.
    CONSTRAINT fk_chamados_prioridade
        FOREIGN KEY (id_prioridade) REFERENCES tb_prioridades (id_prioridade)
        ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relaciona o chamado ao seu status atual.
    CONSTRAINT fk_chamados_status
        FOREIGN KEY (id_status_chamado) REFERENCES tb_status_chamado (id_status_chamado)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- HISTÓRICO DOS CHAMADOS
-- Guarda as mensagens e atualizações realizadas durante o atendimento.
-- Dessa forma, o sistema mantém o histórico de cada chamado.

CREATE TABLE tb_interacoes_chamado (
    id_interacao INT UNSIGNED AUTO_INCREMENT,

    -- Chamado ao qual a interação pertence.
    id_chamado INT UNSIGNED NOT NULL,

    -- Usuário responsável pelo registro da interação.
    id_usuario INT UNSIGNED NOT NULL,

    -- Texto da mensagem ou atualização registrada.
    mensagem TEXT NOT NULL,

    -- Data e hora em que a interação foi criada.
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_tb_interacoes_chamado PRIMARY KEY (id_interacao),

    -- As interações pertencem ao chamado.
    -- Se o chamado for excluído, seu histórico também será removido.
    CONSTRAINT fk_interacoes_chamado
        FOREIGN KEY (id_chamado) REFERENCES tb_chamados (id_chamado)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Mantém registrado qual usuário realizou a interação.
    -- RESTRICT evita excluir usuários que possuem histórico registrado.
    CONSTRAINT fk_interacoes_usuario
        FOREIGN KEY (id_usuario) REFERENCES tb_usuarios (id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- AUDITORIA
-- Registra ações importantes realizadas no sistema.
-- Pode ser utilizado para acompanhar operações como INSERT, UPDATE,
-- DELETE, LOGIN e LOGOUT e auxiliar na identificação de alterações.

CREATE TABLE tb_logs_auditoria (
    id_log BIGINT UNSIGNED AUTO_INCREMENT,

    -- Usuário que realizou a ação.
    -- Pode ser NULL quando a ação não estiver vinculada a um usuário.
    id_usuario INT UNSIGNED NULL,

    -- Tipo da operação realizada no sistema.
    acao VARCHAR(20) NOT NULL COMMENT 'Tipo de operacao: INSERT, UPDATE, DELETE, LOGIN ou LOGOUT',

    -- Nome da tabela afetada pela operação.
    tabela VARCHAR(64) NOT NULL,

    -- ID do registro afetado pela operação.
    id_registro INT UNSIGNED NULL,

    -- Informações adicionais sobre o evento registrado.
    descricao VARCHAR(500) NULL,

    -- Data e hora em que a ação foi registrada.
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_tb_logs_auditoria PRIMARY KEY (id_log),

    -- Permite registrar somente as ações previstas pelo sistema.
    -- Caso surja uma nova ação, esta regra deve ser atualizada.
    CONSTRAINT ck_logs_acao
        CHECK (acao IN ('INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT')),

    -- Se o usuário for removido, o log continua existindo.
    -- Apenas a referência ao usuário passa a ser NULL.
    CONSTRAINT fk_logs_usuario
        FOREIGN KEY (id_usuario) REFERENCES tb_usuarios (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ÍNDICES
-- Os índices ajudam o banco a localizar registros com mais rapidez.
-- Foram criados principalmente para consultas que serão utilizadas
-- com frequência no painel e no gerenciamento do sistema.


-- Usuários e perfis
-- A chave primária atende consultas iniciadas pelo usuário.
-- Este índice atende as consultas iniciadas pelo perfil,
-- como listar todos os usuários que possuem determinado perfil.
CREATE INDEX idx_usuario_perfis_perfil ON tb_usuario_perfis (id_perfil);


-- Contratos
-- Facilita a busca por contratos próximos do vencimento.
CREATE INDEX idx_contratos_data_fim ON tb_contratos (data_fim);

-- Permite filtrar contratos combinando o status com a data de vencimento.
CREATE INDEX idx_contratos_status_data_fim ON tb_contratos (id_status_contrato, data_fim);


-- Chamados
-- Facilita consultas que filtram chamados por empresa e status.
CREATE INDEX idx_chamados_empresa_status ON tb_chamados (id_empresa, id_status_chamado);

-- Facilita consultas dos chamados atribuídos a um responsável,
-- permitindo também filtrar pelo status do atendimento.
CREATE INDEX idx_chamados_responsavel_status ON tb_chamados (id_usuario_responsavel, id_status_chamado);

-- Facilita consultas e ordenações utilizando a data de abertura.
CREATE INDEX idx_chamados_data_abertura ON tb_chamados (data_abertura);


-- Histórico
-- Permite localizar rapidamente as interações de um chamado
-- e recuperá-las na ordem em que foram registradas.
CREATE INDEX idx_interacoes_chamado_data ON tb_interacoes_chamado (id_chamado, created_at);


-- Auditoria
-- Facilita a busca pelas ações realizadas sobre determinada tabela
-- e determinado registro.
CREATE INDEX idx_logs_tabela_registro ON tb_logs_auditoria (tabela, id_registro);

-- Facilita consultas de auditoria por período.
CREATE INDEX idx_logs_data_hora ON tb_logs_auditoria (data_hora);


-- Contatos
-- Facilita a filtragem das mensagens de contato pelo status.
CREATE INDEX idx_contatos_status ON tb_contatos (id_status_contato);


-- DADOS INICIAIS
-- Insere informações básicas utilizadas pelo sistema.
-- Esses registros servem como opções iniciais para os cadastros
-- e evitam que o banco comece sem dados de configuração.


-- Perfis disponíveis para os usuários do sistema.
INSERT INTO tb_perfis (nome, descricao) VALUES
('Administrador', 'Acesso total ao sistema'),
('Gestor',        'Gerencia contratos, empresas e equipe'),
('Técnico',       'Atende e resolve chamados'),
('Atendente',     'Abre e acompanha chamados');


-- Tipos de contrato oferecidos pela Onion Systems.
INSERT INTO tb_tipos_contrato (nome, descricao) VALUES
('Desenvolvimento', 'Desenvolvimento de software sob demanda'),
('Suporte',         'Suporte técnico continuado'),
('Consultoria',     'Consultoria especializada em TI'),
('Infraestrutura',  'Servidores, redes e cloud'),
('Licenciamento',   'Licenças de software'),
('Manutenção',      'Manutenção preventiva e corretiva');


-- Status utilizados para representar a situação de um contrato.
INSERT INTO tb_status_contrato (nome, descricao) VALUES
('Ativo',      'Contrato em vigor'),
('Pendente',   'Aguardando assinatura ou aprovação'),
('Encerrado',  'Contrato finalizado'),
('Cancelado',  'Contrato cancelado antes do término'),
('Renovação',  'Contrato em processo de renovação');


-- Categorias utilizadas para classificar os chamados técnicos.
INSERT INTO tb_categorias (nome, descricao) VALUES
('Hardware',       'Problemas com equipamentos'),
('Software',       'Problemas com programas e aplicativos'),
('Rede',           'Conectividade e infraestrutura de rede'),
('Banco de Dados', 'Problemas com bancos de dados'),
('Sistema',        'Problemas em sistemas e plataformas'),
('Acesso',         'Permissões, senhas e contas'),
('Segurança',      'Incidentes e vulnerabilidades'),
('Outros',         'Demais solicitações');


-- Níveis de prioridade disponíveis para os chamados.
-- O valor numérico permite ordenar os chamados por urgência.
INSERT INTO tb_prioridades (nome, nivel) VALUES
('Baixa',   1),
('Média',   2),
('Alta',    3),
('Urgente', 4);


-- Status que representam as etapas do atendimento de um chamado.
INSERT INTO tb_status_chamado (nome, descricao) VALUES
('Aberto',             'Chamado recém-criado'),
('Em atendimento',     'Em análise ou execução pela equipe'),
('Aguardando cliente', 'Pendente de retorno do cliente'),
('Resolvido',          'Solução aplicada, aguardando confirmação'),
('Fechado',            'Atendimento encerrado'),
('Cancelado',          'Chamado cancelado');


-- Status que representam as etapas do tratamento de uma mensagem de contato.
INSERT INTO tb_status_contato (nome, descricao) VALUES
('Novo',           'Mensagem recebida e ainda não analisada'),
('Em atendimento', 'Mensagem em análise pela equipe'),
('Respondido',     'Retorno já enviado ao visitante'),
('Arquivado',      'Mensagem finalizada e arquivada');


-- Registro utilizado para testar o funcionamento do formulário de contato.
-- O status é localizado pelo nome para não depender do valor do ID gerado.
INSERT INTO tb_contatos (id_status_contato, nome, email, mensagem, consentimento, consentimento_data, consentimento_versao) VALUES
(
    (SELECT id_status_contato FROM tb_status_contato WHERE nome = 'Novo'),
    'João Silva',
    'joao@email.com',
    'Gostaria de saber sobre seus serviços.',
    TRUE,
    NOW(),
    'v1.0'
);


-- VIEWS
-- Views são consultas salvas que permitem reunir informações
-- de várias tabelas e facilitar o acesso aos dados pela aplicação.
--
-- Elas evitam repetir os mesmos JOINs em diferentes consultas.


-- Reúne as principais informações necessárias para consultar contratos.
-- A view combina dados do contrato, empresa, responsável, tipo e status.

CREATE VIEW vw_contratos_completos AS
SELECT
    c.id_contrato,
    c.numero_contrato,
    c.titulo,
    c.descricao,
    c.valor,
    c.data_inicio,
    c.data_fim,

    -- Calcula a quantidade de dias entre a data atual e o vencimento.
    -- Valores negativos indicam contratos que já venceram.
    DATEDIFF(c.data_fim, CURDATE()) AS dias_para_vencimento,

    c.dias_alerta_renovacao,
    c.renovacao_automatica,
    c.observacoes,

    -- Dados da empresa relacionada ao contrato.
    e.id_empresa,
    e.razao_social,
    e.nome_fantasia,

    -- Dados do usuário responsável pelo contrato.
    u.id_usuario AS id_responsavel,
    u.nome AS responsavel,

    -- Tipo e status atual do contrato.
    t.id_tipo_contrato,
    t.nome AS tipo_contrato,

    s.id_status_contrato,
    s.nome AS status_contrato,

    c.created_at,
    c.updated_at

FROM tb_contratos c

-- Recupera os dados da empresa relacionada.
INNER JOIN tb_empresas e
    ON e.id_empresa = c.id_empresa

-- Recupera o usuário responsável pelo contrato.
INNER JOIN tb_usuarios u
    ON u.id_usuario = c.id_responsavel

-- Recupera o tipo do contrato.
INNER JOIN tb_tipos_contrato t
    ON t.id_tipo_contrato = c.id_tipo_contrato

-- Recupera o status atual do contrato.
INNER JOIN tb_status_contrato s
    ON s.id_status_contrato = c.id_status_contrato;


-- Reúne as principais informações necessárias para consultar chamados.
-- A view combina empresa, usuários, categoria, prioridade e status.

CREATE VIEW vw_chamados_completos AS
SELECT
    ch.id_chamado,
    ch.titulo,
    ch.descricao,
    ch.data_abertura,
    ch.data_fechamento,

    -- Data da última alteração realizada no chamado.
    ch.updated_at AS data_atualizacao,

    -- Dados da empresa relacionada ao chamado.
    e.id_empresa,
    e.razao_social,
    e.nome_fantasia,

    -- Usuário responsável pela abertura do chamado.
    ua.id_usuario AS id_usuario_abertura,
    ua.nome AS usuario_abertura,

    -- Usuário atualmente responsável pelo atendimento.
    ur.id_usuario AS id_usuario_responsavel,
    ur.nome AS responsavel,

    -- Categoria e prioridade utilizadas no atendimento.
    cat.id_categoria,
    cat.nome AS categoria,

    p.id_prioridade,
    p.nome AS prioridade,
    p.nivel AS prioridade_nivel,

    -- Status atual do chamado.
    st.id_status_chamado,
    st.nome AS status_chamado

FROM tb_chamados ch

-- Recupera os dados da empresa que abriu o chamado.
INNER JOIN tb_empresas e
    ON e.id_empresa = ch.id_empresa

-- Recupera o usuário que realizou a abertura.
INNER JOIN tb_usuarios ua
    ON ua.id_usuario = ch.id_usuario_abertura

-- LEFT JOIN é utilizado porque um chamado pode ainda não possuir
-- um usuário responsável pelo atendimento.
LEFT JOIN tb_usuarios ur
    ON ur.id_usuario = ch.id_usuario_responsavel

-- Recupera a categoria do chamado.
INNER JOIN tb_categorias cat
    ON cat.id_categoria = ch.id_categoria

-- Recupera a prioridade do chamado.
INNER JOIN tb_prioridades p
    ON p.id_prioridade = ch.id_prioridade

-- Recupera o status atual do chamado.
INNER JOIN tb_status_chamado st
    ON st.id_status_chamado = ch.id_status_chamado;


-- EXEMPLO DE CONSULTA
-- Consulta contratos ativos que possuem vencimento nos próximos 30 dias.
-- A view já calcula a quantidade de dias restantes para cada contrato.

-- SELECT *
-- FROM vw_contratos_completos
-- WHERE dias_para_vencimento BETWEEN 0 AND 30
--   AND status_contrato = 'Ativo';