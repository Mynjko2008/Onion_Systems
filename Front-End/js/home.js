document.addEventListener("DOMContentLoaded", function () {
    const swiperHero = new Swiper(".swiper-hero", {
        loop: true,
        autoplay: {
            delay: 5000,
            disableOnInteraction: false,
        },
        navigation: {
            nextEl: ".swiper-hero .swiper-button-next",
            prevEl: ".swiper-hero .swiper-button-prev",
        },
        pagination: {
            el: ".swiper-hero .swiper-pagination",
            clickable: true,
        },
    });
    const swiperBlog = new Swiper(".swiper-blog", {
        loop: true,
        autoplay: {
            delay: 4000,
            disableOnInteraction: false,
        },
        navigation: {
            nextEl: ".swiper-blog .swiper-button-next",
            prevEl: ".swiper-blog .swiper-button-prev",
        },
    });
    const navLinks = document.querySelectorAll('.menu-navegacao a');
    const sections = document.querySelectorAll('section');

    window.addEventListener('scroll', () => {
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (pageYOffset >= (sectionTop - 150)) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
    const formContato = document.querySelector("#formContato");
    if (formContato) {
        formContato.addEventListener("submit", function (e) {
            e.preventDefault();
            alert("Sua mensagem foi enviada com sucesso! Em breve a equipe da Onion Systems entrará em contato.");
            formContato.reset();
        });
    }
});