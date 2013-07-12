onReady(function() {
    var songLinks, audio;

    audio = document.createElement("audio");

    if (!!audio.canPlayType) {
        songLinks = document.querySelectorAll("#songs ul li a");

        if (songLinks && songLinks.length > 0) {
            audio.setAttribute("id", "audio-player");

            audio.setAttribute("controls", true);

            audio.setAttribute("autoplay", true);

            document.querySelectorAll("body")[0].appendChild(audio);

            for (var i = 0; i < songLinks.length; ++i) {
                songLinks[i].addEventListener("click", function(event) {
                    var songLink, onEndedHandler;

                    event.preventDefault();

                    songLink = this;

                    for (var j = 0; j < songLinks.length; ++j) {
                        songLinks[j].classList.remove("playing");
                    }

                    if (!!audio.canPlayType(getFormat(songLink.href.split(".").slice(-1)[0])).replace(/no/, "")) {
                        songLink.classList.add("playing");

                        audio.setAttribute("src", songLink.href);

                        onEndedHandler = function() {
                            songLink.classList.remove("playing");

                            audio.removeEventListener("ended", onEndedHandler, false);

                            if (songLink.parentNode.nextElementSibling && songLink.parentNode.nextElementSibling.querySelector("a")) {
                                songLink.parentNode.nextElementSibling.querySelector("a").click();
                            }
                        };

                        audio.addEventListener("ended", onEndedHandler, false);
                    } else {
                        songLink.classList.add("error");
                    }
                }, false);
            }
        }
    }
});

function getFormat(extension) {
    return {
        "mp3": "audio/mpeg;",
        "ogg": "audio/ogg; codecs=\"vorbis\"",
        "m4a": "audio/mp4; codecs=\"mp4a.40.2\"",
        "wav": "audio/wav; codecs=\"1\""
    }[extension];
}

function onReady(completed) {
    if (document.readyState === "complete") {
        setTimeout(completed);
    } else {
        document.addEventListener("DOMContentLoaded", completed, false);
    }
}
