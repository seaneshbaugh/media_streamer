onReady(function() {
    var songLinks, audio, volume, loop;

    audio = document.createElement("audio");

    if (!!audio.canPlayType) {
        songLinks = document.querySelectorAll("#songs ul li a");

        if (songLinks && songLinks.length > 0) {
            audio.setAttribute("id", "audio-player");

            audio.setAttribute("controls", true);

            audio.setAttribute("autoplay", true);

            volume = getCookie("media-streamer-volume");

            if (volume !== null) {
                audio.volume = volume;
            }

            audio.addEventListener("volumechange", function() {
                setCookie("media-streamer-volume", audio.volume);
            });

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
                            } else {
                                if (loop && loop.checked) {
                                    songLinks[0].click();
                                }
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

    loop = document.getElementById("loop");

    if (loop) {
        if (getCookie("media-streamer-loop")) {
            loop.checked = true;
        }

        loop.addEventListener("click", function() {
            if (loop.checked) {
                setCookie("media-streamer-loop", true);
            } else {
                removeCookie("media-streamer-loop");
            }
        }, false);
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

function getCookie(cookieName) {
    var cookieValue;

    cookieName = cookieName.trim();

    if (cookieName[cookieName.length - 1] !== "=") {
        cookieName += "=";
    }

    cookieValue = null;

    document.cookie.split(";").forEach(function(cookie) {
        cookie = cookie.trim();

        if (cookie.indexOf(cookieName) === 0) {
            cookieValue = cookie.substring(cookieName.length, cookie.length);
        }
    });

    return cookieValue;
}

function setCookie(cookieName, cookieValue, expirationTime) {
    cookieName = cookieName.trim();

    if (cookieName[cookieName.length - 1] !== "=") {
        cookieName += "=";
    }

    if (expirationTime) {
        expirationTime = new Date(expirationTime);

        if (expirationTime.toUTCString() !== "Invalid Date") {
            expirationTime = "; expires=" + expirationTime.toUTCString();
        } else {
            expirationTime = "";
        }
    } else {
        expirationTime = "";
    }

    document.cookie = cookieName + cookieValue + expirationTime + "; path=/";

    return cookieValue;
}

function removeCookie(cookieName) {
    setCookie(cookieName, "", -1);

    return "";
}

function onReady(completed) {
    if (document.readyState === "complete") {
        setTimeout(completed);
    } else {
        document.addEventListener("DOMContentLoaded", completed, false);
    }
}
