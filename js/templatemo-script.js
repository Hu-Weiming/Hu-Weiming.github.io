const initBg = (autoplay = true) => {
    // const bgImgsNames = ['diagoona-bg-1.jpg', 'diagoona-bg-2.jpg', 'diagoona-bg-3.jpg'];
    const bgImgsNames = [
        'https://s2.loli.net/2022/03/06/bhir6WFGTBIdyQN.jpg',
        'https://s2.loli.net/2022/03/06/wHeVatpidWOFyG8.png',
        'https://s2.loli.net/2022/03/06/pi7NJlETLz82gM1.jpg',
        'https://s2.loli.net/2022/03/06/QNujdVvP8wRbzMH.png'];
    const bgImgs = bgImgsNames.map(img => img);

    $.backstretch(bgImgs, {duration: 1000, fade: 500});

    if (!autoplay) {
        $.backstretch('pause');
    }
}

const setBg = id => {
    $.backstretch('show', id);
}

const setBgOverlay = () => {
    const windowWidth = window.innerWidth;
    const bgHeight = $('body').height();
    const tmBgLeft = $('.tm-bg-left');

    $('.tm-bg').height(bgHeight);

    if (windowWidth > 768) {
        tmBgLeft.css('border-left', `0`)
            .css('border-top', `${bgHeight}px solid transparent`);
    } else {
        tmBgLeft.css('border-left', `${windowWidth}px solid transparent`)
            .css('border-top', `0`);
    }
}

$(document).ready(function () {
    const autoplayBg = true;	// set Auto Play for Background Images
    initBg(autoplayBg);
    setBgOverlay();

    const bgControl = $('.tm-bg-control');
    bgControl.click(function () {
        bgControl.removeClass('active');
        $(this).addClass('active');
        const id = $(this).data('id');
        setBg(id);
    });

    $(window).on("backstretch.after", function (e, instance, index) {
        const bgControl = $('.tm-bg-control');
        bgControl.removeClass('active');
        const current = $(".tm-bg-controls-wrapper").find(`[data-id=${index}]`);
        current.addClass('active');
    });

    $(window).resize(function () {
        setBgOverlay();
    });
});