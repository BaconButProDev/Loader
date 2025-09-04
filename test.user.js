// ==UserScript==
// @name         Auto Button Runner
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Hiện nút "Click Here" để chạy code bypass
// @author       You
// @match        *://work.ink/*
// @match        *://workink.net/*
// @grant        none
// ==/UserScript==
(function () {
  'use strict';
  function createButton() {
    const btn = document.createElement("button");
    btn.innerText = "Bypass";
    btn.style.cssText = `
      position: fixed;
      top: 20px;
      left: 50%;
      transform: translateX(-50%);
      z-index: 9999;
      padding: 12px 24px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      border: none;
      border-radius: 25px;
      cursor: pointer;
      font-weight: 600;
      box-shadow: 0 4px 15px rgba(0,0,0,0.2);
      transition: all 0.3s ease;
    `;
    btn.onmouseover = () => btn.style.transform = "translateX(-50%) translateY(-2px) scale(1.05)";
    btn.onmouseout = () => btn.style.transform = "translateX(-50%)";

    document.body.appendChild(btn);
    btn.addEventListener("click", async () => {
      (async () => {
        var _0x321b52 = window.setTimeout;
        var _0x5f0cd2 = window.setInterval;
        window.setTimeout = (_0x1cde6a, _0x2a961d) => {
          if (_0x2a961d > 0) {
            _0x2a961d = 1;
          }
          return _0x321b52(_0x1cde6a, _0x2a961d);
        };
        window.setInterval = (_0x3d81bc, _0x299d8d) => {
          if (_0x299d8d > 0) {
            _0x299d8d = 1;
          }
          return _0x5f0cd2(_0x3d81bc, _0x299d8d);
        };
        function _0x26e803(_0x20d248, _0x3964c2 = 5000, _0x38b750 = 100) {
          return new Promise((_0x4d8590, _0xf9c8b1) => {
            const _0x1a70a6 = Date.now();
            (function _0x38860b() {
              const _0x85f172 = document.querySelector(_0x20d248);
              if (_0x85f172) {
                return _0x4d8590(_0x85f172);
              }
              if (Date.now() - _0x1a70a6 > _0x3964c2) {
                return _0xf9c8b1();
              }
              _0x321b52(_0x38860b, _0x38b750);
            })();
          });
        }
        function _0x51b3ef(_0xf1b9cc) {
          return new Promise(_0xd227bc => _0x321b52(_0xd227bc, _0xf1b9cc));
        }
        async function _0x49eefd(_0x2f51fb, _0x2fb561, _0x4c6a98) {
          for (let _0x565f3c = 0; _0x565f3c < _0x2fb561; _0x565f3c++) {
            _0x2f51fb.click();
            await _0x51b3ef(_0x4c6a98);
          }
        }
        try {
          const _0x1708d5 = await _0x26e803(".accessBtn");
          _0x1708d5.click();
          const _0x24e757 = await _0x26e803("button.w-full.bg-gray-100");
          await _0x49eefd(_0x24e757, 5, 250);
          const _0x3f37a2 = "div.button.large.accessBtn.pos-relative.svelte-iyommg";
          const _0x1ed6e4 = await _0x26e803(_0x3f37a2);
          _0x1ed6e4.click();
          try {
            const _0x3d311a = await _0x26e803("button.w-full.bg-emerald-600.text-white.rounded-full");
            _0x3d311a.click();
          } catch {
            const _0x753cb4 = await _0x26e803("#access-offers");
            await _0x49eefd(_0x753cb4, 5, 250);
            return;
          }
          try {
            const _0x5d4cf0 = await _0x26e803(".closelabel");
            _0x5d4cf0.click();
          } catch {
            const _0x529a41 = await _0x26e803("#access-offers");
            await _0x49eefd(_0x529a41, 5, 250);
            return;
          }
          const _0xd94d77 = await _0x26e803(".skipBtn");
          _0xd94d77.click();
          const _0x214697 = await _0x26e803("#access-offers");
          await _0x49eefd(_0x214697, 5, 250);
        } catch {}
      })();
    });
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", createButton);
  } else {
    createButton();
  }
})();
