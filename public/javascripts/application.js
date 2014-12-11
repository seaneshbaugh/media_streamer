onReady(function() {
    var songLinks, audio, volume, loop, randomOff, randomSong, randomAlbum, skipRandom;

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

            for (var i = 0; i < songLinks.length; i += 1) {
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

                            if (randomSong && randomSong.checked) {
                                randomAlbumJump(true);
                            } else {
                                if (songLink.parentNode.nextElementSibling && songLink.parentNode.nextElementSibling.querySelector("a")) {
                                    songLink.parentNode.nextElementSibling.querySelector("a").click();
                                } else {
                                    if (randomAlbum && randomAlbum.checked) {
                                        randomAlbumJump(false);
                                    } else {
                                        if (loop && loop.checked) {
                                            songLinks[0].click();
                                        }
                                    }
                                 }
                             }
                        };

                        audio.addEventListener("ended", onEndedHandler, false);
                    } else {
                        songLink.classList.add("error");
                    }
                }, false);
            }

            if (getCookie("random-song-jump")) {
                removeCookie("random-song-jump");

                songLinks[Math.floor(Math.random() * songLinks.length)].click();
            }

            if (getCookie("random-album-jump")) {
                removeCookie("random-album-jump");

                songLinks[0].click();
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

    randomOff = document.getElementById("random-off");

    randomSong = document.getElementById("random-song");

    randomAlbum = document.getElementById("random-album");

    if (randomOff && randomSong && randomAlbum) {
        if (getCookie("media-streamer-random-song")) {
            randomSong.checked = true;
        } else {
            if (getCookie("media-streamer-random-album")) {
                randomAlbum.checked = true;
            }
        }

        randomOff.addEventListener("click", function() {
            removeCookie("media-streamer-random-song");

            removeCookie("media-streamer-random-album");

            if (skipRandom) {
                skipRandom.setAttribute("style", "display: none;");
            }
        }, false);

        randomSong.addEventListener("click", function() {
            setCookie("media-streamer-random-song", true);

            removeCookie("media-streamer-random-album");

            if (skipRandom) {
                skipRandom.setAttribute("style", "display: inline;");
            }
        }, false);

        randomAlbum.addEventListener("click", function() {
            setCookie("media-streamer-random-album", true);

            removeCookie("media-streamer-random-song");

            if (skipRandom) {
                skipRandom.setAttribute("style", "display: inline;");
            }
        }, false);
    }

    skipRandom = document.getElementById("skip-random");

    if (skipRandom) {
        skipRandom.addEventListener("click", function() {
            if (randomSong && randomSong.checked) {
                randomAlbumJump(true);
            } else {
                if (randomAlbum && randomAlbum.checked) {
                    randomAlbumJump(false);
                }
            }
        }, false);

        if ((randomSong && randomSong.checked) || (randomAlbum && randomAlbum.checked)) {
            skipRandom.setAttribute("style", "display: inline;");
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

function randomAlbumJump(playSong) {
    var artistsApiRequest, artsitsData, artistApiRequest, artistData;

    artistsApiRequest = new XMLHttpRequest();

    artistsApiRequest.open("GET", "/api/v1", true)

    artistsApiRequest.onload = function() {
        var nextArtistUrl;

        if (artistsApiRequest.status >= 200 && artistsApiRequest.status < 400) {
            artsitsData = JSON.parse(artistsApiRequest.responseText);

            nextArtistUrl = artsitsData.artists[Math.floor(Math.random() * artsitsData.artists.length)].api_url;

            artistApiRequest = new XMLHttpRequest();

            artistApiRequest.open("GET", nextArtistUrl);

            artistApiRequest.onload = function() {
                var nextAlbumUrl;

                if (artistApiRequest.status >= 200 && artistApiRequest.status < 400) {
                    artistData = JSON.parse(artistApiRequest.responseText);

                    nextAlbumUrl = artistData.artist.albums[Math.floor(Math.random() * artistData.artist.albums.length)].url;

                    if (playSong) {
                        setCookie("random-song-jump", true);
                    } else {
                        setCookie("random-album-jump", true);
                    }

                    window.location = nextAlbumUrl;
                } else {
                    console.log("Error retrieving albums.")
                }
            };

            artistApiRequest.onerror = function() {
                console.log("Error retrieving albums.")
            }

            artistApiRequest.send();
        } else {
            console.log("Error retrieving artists.");
        }
    };

    artistsApiRequest.onerror = function() {
        console.log("Error retrieving artists.");
    };

    artistsApiRequest.send();
}

function onReady(completed) {
    if (document.readyState === "complete") {
        setTimeout(completed);
    } else {
        document.addEventListener("DOMContentLoaded", completed, false);
    }
}
