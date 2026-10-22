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

  // --- sidebar filter ----------------------------------------------------
  // Filters the items in the sidebar, hiding groups that match nothing.
  var filterInputs = document.querySelectorAll('.side-filter');
  Array.prototype.forEach.call(filterInputs, function (input) {
    var side = input.closest('.side');
    if (!side) return;
    var clear = side.querySelector('.side-clear');
    var groups = side.querySelectorAll('.side-group');
    var items = side.querySelectorAll('[data-side-item]');

    function apply() {
      var query = input.value.trim().toLowerCase();
      var hits = 0;

      Array.prototype.forEach.call(items, function (item) {
        var hay = item.getAttribute('data-label') || item.textContent || '';
        var match = query === '' || hay.indexOf(query) !== -1;
        item.hidden = !match;
        if (match) hits += 1;
      });

      // Hide a group when nothing inside it matches.
      Array.prototype.forEach.call(groups, function (group) {
        var own = group.querySelectorAll('[data-side-item]');
        var shown = Array.prototype.filter.call(own, function (i) { return !i.hidden; });
        group.hidden = query !== '' && shown.length === 0;
        // While filtering, force groups open so matches are visible.
        if (query !== '') {
          group.classList.add('open');
        }
      });

      if (clear) clear.hidden = query === '';

      var empty = side.querySelector('.side-empty');
      if (query !== '' && hits === 0) {
        if (!empty) {
          empty = document.createElement('p');
          empty.className = 'side-empty';
          empty.textContent = '没有匹配项';
          side.appendChild(empty);
        }
        empty.hidden = false;
      } else if (empty) {
        empty.hidden = true;
      }
    }

    input.addEventListener('input', apply);
    if (clear) {
      clear.addEventListener('click', function () {
        input.value = '';
        apply();
        input.focus();
      });
    }
    // "/" focuses the sidebar filter, the way it focuses search elsewhere.
    input.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') {
        input.value = '';
        apply();
        input.blur();
      }
    });
  });

  // --- sidebar group collapse --------------------------------------------
  // Each group header is a button; clicking toggles its item list.
  var heads = document.querySelectorAll('.side-head');
  Array.prototype.forEach.call(heads, function (head) {
    if (!head.classList.contains('side-head')) return;
    var group = head.closest('.side-group');
    if (!group) return;
    head.addEventListener('click', function () {
      var open = group.classList.toggle('open');
      head.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  });

  // "/" focuses the sidebar filter when nothing else is being typed into.
  document.addEventListener('keydown', function (event) {
    var tag = (event.target.tagName || '').toLowerCase();
    if (tag === 'input' || tag === 'textarea') return;
    if (event.key === '/' && !event.metaKey && !event.ctrlKey) {
      var box = document.querySelector('.side-filter');
      if (box) {
        event.preventDefault();
        box.focus();
        box.select();
      }
    }
  });

  // --- site-wide search --------------------------------------------------
  var dataEl = document.getElementById('search-data');
  if (dataEl) {
    var docs = [];
    try { docs = JSON.parse(dataEl.textContent); } catch (e) { docs = []; }

    var input = document.getElementById('site-search');
    var results = document.getElementById('search-results');
    var meta = document.getElementById('search-meta');

    function score(doc, q) {
      var title = doc.t.toLowerCase();
      var body = (doc.s || '').toLowerCase();
      var i = title.indexOf(q);
      if (i === 0) return 100;
      if (i > 0) return 70;
      if (body.indexOf(q) !== -1) return 30;
      return 0;
    }

    function render(q) {
      q = q.trim().toLowerCase();
      if (q === '') {
        results.innerHTML = '';
        if (meta) meta.textContent = docs.length + ' 个页面可搜索';
        return;
      }
      var scored = [];
      docs.forEach(function (d) {
        var v = score(d, q);
        if (v > 0) scored.push({ d: d, v: v });
      });
      scored.sort(function (a, b) { return b.v - a.v; });
      var top = scored.slice(0, 40);

      if (meta) meta.textContent = top.length ? top.length + ' 个结果（最多显示 40）' : '没有匹配项';

      results.innerHTML = top.map(function (hit) {
        var d = hit.d;
        return '<a class="hit" href="' + d.u + '">'
          + '<span class="hit-kind">' + (d.k || '') + '</span>'
          + '<strong>' + d.t + '</strong>'
          + '<em>' + (d.s || '') + '</em>'
          + '</a>';
      }).join('');
    }

    if (input) {
      var last = '';
      input.addEventListener('input', function () {
        var v = input.value;
        if (v === last) return;
        last = v;
        render(v);
      });
      render(input.value || '');
    }

    document.addEventListener('keydown', function (event) {
      if (event.key === '/' && !event.metaKey && !event.ctrlKey) {
        var tag = (event.target.tagName || '').toLowerCase();
        if (tag === 'input' || tag === 'textarea') return;
        if (input) { event.preventDefault(); input.focus(); input.select(); }
      }
    });
  }
})();
