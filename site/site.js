/* Mobile nav toggle and theme switch. Two small behaviours, no framework. */

(function () {
  'use strict';

  var root = document.documentElement;

  // --- theme -------------------------------------------------------------
  // Dark is the default for a terminal tool; the choice is remembered.
  var stored = null;
  try { stored = localStorage.getItem('nvim-theme'); } catch (e) {}
  if (stored === 'light' || stored === 'dark') {
    root.setAttribute('data-theme', stored);
  }

  var themeBtn = document.getElementById('theme-btn');
  if (themeBtn) {
    themeBtn.addEventListener('click', function () {
      var next = root.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem('nvim-theme', next); } catch (e) {}
    });
  }

  // --- mobile navigation -------------------------------------------------
  var navBtn = document.getElementById('nav-btn');
  var nav = document.getElementById('site-nav');
  if (navBtn && nav) {
    navBtn.addEventListener('click', function () {
      var open = nav.classList.toggle('open');
      navBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
    // Following a link should not leave the menu covering the page.
    nav.addEventListener('click', function (event) {
      if (event.target.closest('a') && nav.classList.contains('open')) {
        nav.classList.remove('open');
        navBtn.setAttribute('aria-expanded', 'false');
      }
    });
  }
})();
