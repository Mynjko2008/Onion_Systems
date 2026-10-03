document.addEventListener("DOMContentLoaded", function () {

    // Endereço da API de contato, resolvido em relação à página atual.
    // Isso mantém o caminho correto mesmo quando o projeto for servido
    // em um subdiretório do servidor local ou em produção.
    const URL_API_CONTATO = new URL(
        "../Back-End/api/contato.php",
        window.location.href
    ).toString();

    // Limites iguais aos do back-end (Back-End/config/config.php).
    // O servidor sempre valida de novo: aqui serve apenas para
    // avisar o visitante mais rápido, sem esperar a resposta.
    const LIMITES = {
        nomeMin: 2,
        nomeMax: 150,
        emailMax: 150,
        mensagemMin: 10,
        mensagemMax: 2000
    };

    // Tempo máximo de espera pela resposta do servidor (em milissegundos)
    const TEMPO_LIMITE = 15000;

    const form = document.getElementById("formContato");
    const status = document.getElementById("formStatus");

    // Se a página não tiver o formulário, não há nada a fazer
    if (!form || !status) {
        return;
    }

    const botao = form.querySelector("button[type='submit']");

    const campos = {
        nome: form.elements["nome"],
        email: form.elements["email"],
        mensagem: form.elements["mensagem"],
        consentimento: form.elements["consentimento"]
    };

    // Impede envios repetidos enquanto a requisição está em andamento
    let enviando = false;

    // Mostra uma mensagem abaixo do formulário.
    // tipo: "sucesso", "erro" ou vazio (mensagem neutra)
    function mostrarStatus(texto, tipo) {
        status.textContent = texto;
        status.className = "form-status" + (tipo ? " " + tipo : "");
    }

    // Remove a marcação de erro de todos os campos
    function limparErros() {
        Object.keys(campos).forEach(function (nome) {
            campos[nome].removeAttribute("aria-invalid");
        });
    }

    // Marca o campo com problema, mostra o erro e leva o foco até ele
    function mostrarErroCampo(nomeCampo, mensagem) {
        limparErros();
        mostrarStatus(mensagem, "erro");

        if (Object.prototype.hasOwnProperty.call(campos, nomeCampo)) {
            campos[nomeCampo].setAttribute("aria-invalid", "true");
            campos[nomeCampo].focus();
        }
    }

    // Valida os campos. Devolve { campo, mensagem } no primeiro erro
    // encontrado, ou null quando está tudo certo.
    function validar() {
        const nome = campos.nome.value.trim();
        const email = campos.email.value.trim();
        const mensagem = campos.mensagem.value.trim();

        if (nome === "") {
            return { campo: "nome", mensagem: "Digite seu nome." };
        }

        if (nome.length < LIMITES.nomeMin || !/\p{L}/u.test(nome)) {
            return { campo: "nome", mensagem: "Nome inválido." };
        }

        if (nome.length > LIMITES.nomeMax) {
            return {
                campo: "nome",
                mensagem: "O nome deve ter no máximo " + LIMITES.nomeMax + " caracteres."
            };
        }

        if (email === "") {
            return { campo: "email", mensagem: "Digite seu e-mail." };
        }

        if (!campos.email.checkValidity() || email.length > LIMITES.emailMax) {
            return { campo: "email", mensagem: "E-mail inválido." };
        }

        if (mensagem === "") {
            return { campo: "mensagem", mensagem: "Digite sua mensagem." };
        }

        if (mensagem.length < LIMITES.mensagemMin) {
            return {
                campo: "mensagem",
                mensagem: "A mensagem deve ter pelo menos " + LIMITES.mensagemMin + " caracteres."
            };
        }

        if (mensagem.length > LIMITES.mensagemMax) {
            return {
                campo: "mensagem",
                mensagem: "A mensagem deve ter no máximo " + LIMITES.mensagemMax + " caracteres."
            };
        }

        if (!campos.consentimento.checked) {
            return {
                campo: "consentimento",
                mensagem: "Você precisa concordar com a política de privacidade para enviar a mensagem."
            };
        }

        return null;
    }

    // Lê o JSON da resposta. Se o servidor devolver outra coisa
    // (por exemplo, uma página de erro em HTML), devolve null.
    async function lerJson(resposta) {
        try {
            return await resposta.json();
        } catch (erro) {
            return null;
        }
    }

    // Quando o visitante corrige um campo, a marcação de erro some
    form.addEventListener("input", function (evento) {
        if (evento.target.hasAttribute("aria-invalid")) {
            evento.target.removeAttribute("aria-invalid");
        }
    });

    form.addEventListener("submit", async function (evento) {

        // Evita o envio padrão do navegador, que recarregaria a página
        evento.preventDefault();

        if (enviando) {
            return;
        }

        limparErros();

        const erro = validar();

        if (erro) {
            mostrarErroCampo(erro.campo, erro.mensagem);
            return;
        }

        enviando = true;
        botao.disabled = true;
        mostrarStatus("Enviando...", "");

        // Cancela a requisição se o servidor demorar demais
        const controlador = new AbortController();
        const temporizador = setTimeout(function () {
            controlador.abort();
        }, TEMPO_LIMITE);

        try {
            const resposta = await fetch(URL_API_CONTATO, {
                method: "POST",

                // FormData envia os campos do formulário, incluindo o
                // checkbox de consentimento (que chega ao PHP como "on")
                body: new FormData(form),
                signal: controlador.signal
            });

            const dados = await lerJson(resposta);

            if (dados && dados.sucesso) {
                form.reset();
                mostrarStatus(dados.mensagem, "sucesso");
                return;
            }

            const mensagem =
                dados && dados.mensagem
                    ? dados.mensagem
                    : "Não foi possível enviar sua mensagem. Tente novamente em instantes.";

            // O back-end informa qual campo causou o erro
            if (dados && dados.campo) {
                mostrarErroCampo(dados.campo, mensagem);
            } else {
                mostrarStatus(mensagem, "erro");
            }

        } catch (erro) {
            mostrarStatus(
                erro.name === "AbortError"
                    ? "O envio demorou demais. Tente novamente."
                    : "Não foi possível enviar. Verifique sua conexão e tente novamente.",
                "erro"
            );

        } finally {
            clearTimeout(temporizador);
            enviando = false;
            botao.disabled = false;
        }
    });

});