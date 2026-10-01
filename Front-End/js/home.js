document.addEventListener("DOMContentLoaded", function () {

    const reduzMovimento =
        window.matchMedia &&
        window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    // Carrosséis
    if (typeof Swiper !== "undefined") {

        // Carrossel principal
        const swiperHeroElement = document.querySelector(".swiper-hero");

        if (swiperHeroElement) {

            const swiperHero = new Swiper(swiperHeroElement, {
                loop: true,

                autoplay: reduzMovimento
                    ? false
                    : {
                        delay: 5000,
                        disableOnInteraction: false,
                        pauseOnMouseEnter: true
                    },

                pagination: {
                    el: ".swiper-hero .swiper-pagination",
                    clickable: true
                },

                observer: true,
                observeParents: true,
                watchOverflow: false,
                speed: 600,

                // Permite que os botões funcionem normalmente
                preventClicks: false,
                preventClicksPropagation: false
            });

            const botaoHeroNext =
                swiperHeroElement.querySelector(".swiper-button-next");

            const botaoHeroPrev =
                swiperHeroElement.querySelector(".swiper-button-prev");

            if (botaoHeroNext) {
                botaoHeroNext.addEventListener(
                    "click",
                    function (evento) {
                        evento.preventDefault();
                        evento.stopPropagation();
                        swiperHero.slideNext();
                    },
                    true
                );
            }

            if (botaoHeroPrev) {
                botaoHeroPrev.addEventListener(
                    "click",
                    function (evento) {
                        evento.preventDefault();
                        evento.stopPropagation();
                        swiperHero.slidePrev();
                    },
                    true
                );
            }
        }

        // Carrossel do blog
        const swiperBlogElement = document.querySelector(".swiper-blog");

        if (swiperBlogElement) {

            const swiperBlog = new Swiper(swiperBlogElement, {
                loop: true,

                autoplay: reduzMovimento
                    ? false
                    : {
                        delay: 4000,
                        disableOnInteraction: false,
                        pauseOnMouseEnter: true
                    },

                observer: true,
                observeParents: true,
                watchOverflow: false,
                speed: 600,

                preventClicks: false,
                preventClicksPropagation: false
            });

            const botaoBlogNext =
                swiperBlogElement.querySelector(".swiper-button-next");

            const botaoBlogPrev =
                swiperBlogElement.querySelector(".swiper-button-prev");

            if (botaoBlogNext) {
                botaoBlogNext.addEventListener(
                    "click",
                    function (evento) {
                        evento.preventDefault();
                        evento.stopPropagation();
                        swiperBlog.slideNext();
                    },
                    true
                );
            }

            if (botaoBlogPrev) {
                botaoBlogPrev.addEventListener(
                    "click",
                    function (evento) {
                        evento.preventDefault();
                        evento.stopPropagation();
                        swiperBlog.slidePrev();
                    },
                    true
                );
            }
        }

    } else {
        console.error(
            "Swiper não foi carregado. Verifique o CDN no HTML."
        );
    }

    // Menu mobile
    const menuButton = document.querySelector(".menu-toggle");
    const menu = document.querySelector(".menu-navegacao");

    if (menuButton && menu) {

        menuButton.addEventListener("click", function () {

            // Abre ou fecha o menu
            menu.classList.toggle("aberto");

            const aberto =
                menu.classList.contains("aberto");

            menuButton.setAttribute(
                "aria-expanded",
                aberto
            );
        });

        const linksMenu =
            menu.querySelectorAll("a");

        linksMenu.forEach(function (link) {

            link.addEventListener("click", function () {

                // Fecha o menu depois de clicar em um link
                menu.classList.remove("aberto");

                menuButton.setAttribute(
                    "aria-expanded",
                    "false"
                );
            });
        });
    }

    // Fecha o menu ao redimensionar a tela
    window.addEventListener("resize", function () {

        if (
            window.innerWidth > 768 &&
            menu &&
            menuButton
        ) {
            menu.classList.remove("aberto");

            menuButton.setAttribute(
                "aria-expanded",
                "false"
            );
        }
    });

});