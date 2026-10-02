<?php
// ENDPOINT PÚBLICO: POST /Back-End/api/contato.php
// Recebe o formulário de contato do site e grava em tb_contatos.
// Este arquivo apenas carrega as camadas e entrega a requisição ao controller.

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../config/conexao.php';
require_once __DIR__ . '/../helpers/resposta.php';
require_once __DIR__ . '/../helpers/validacao.php';
require_once __DIR__ . '/../models/contato.php';
require_once __DIR__ . '/../services/contatoService.php';
require_once __DIR__ . '/../controllers/contatoController.php';

$controller = new ContatoController();
$controller->tratarRequisicao();
