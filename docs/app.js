(function () {
  'use strict';

  function initNav() {
    var nav = document.querySelector('.lp-nav');
    var btn = document.querySelector('.lp-nav-toggle');
    var menu = document.getElementById('lp-nav-menu');
    if (!nav || !btn || !menu) return;

    function setOpen(open) {
      nav.classList.toggle('is-open', open);
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      btn.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    }

    btn.addEventListener('click', function () {
      setOpen(!nav.classList.contains('is-open'));
    });

    menu.querySelectorAll('a[href^="#"]').forEach(function (link) {
      link.addEventListener('click', function () { setOpen(false); });
    });

    document.addEventListener('keydown', function (event) {
      if (event.key === 'Escape') setOpen(false);
    });

    window.addEventListener('resize', function () {
      if (window.innerWidth > 860) setOpen(false);
    });
  }

  function initDemo() {
    var demo = document.getElementById('demo-stage');
    var modeButtons = document.querySelectorAll('[data-demo-kind]');
    var title = document.getElementById('demo-title');
    var message = document.getElementById('demo-message');
    var timer = document.getElementById('demo-timer');
    var nextEye = document.getElementById('next-eye');
    var nextStand = document.getElementById('next-stand');
    var status = document.getElementById('demo-status');
    var icon = document.getElementById('demo-break-icon');
    var overlay = demo.querySelector('.overlay-card');
    var actionButtons = demo.querySelectorAll('[data-demo-action]');
    if (!demo || !title || !message || !timer || !nextEye || !nextStand || !status || !icon || !overlay) return;

    var data = {
      eyes: {
        title: 'Rest your eyes',
        message: 'Look at the farthest point you can see. Blink slowly.',
        seconds: 20,
        nextEye: 'Now',
        nextStand: '40m 00s',
        status: 'Eye break in progress',
        icon: 'eye'
      },
      stand: {
        title: 'Stand up and look far away',
        message: 'Step away from the screen, stretch, and look into the distance.',
        seconds: 90,
        nextEye: 'After stand break',
        nextStand: 'Now',
        status: 'Stand break in progress',
        icon: 'stand'
      }
    };
    var countdownId = null;
    var restartId = null;
    var activeKind = 'eyes';
    var remainingSeconds = data.eyes.seconds;

    function formatTime(totalSeconds) {
      var safeSeconds = Math.max(0, totalSeconds);
      var minutes = Math.floor(safeSeconds / 60);
      var seconds = safeSeconds % 60;
      return String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
    }

    function stopCountdown() {
      if (countdownId) {
        window.clearInterval(countdownId);
        countdownId = null;
      }
    }

    function stopRestart() {
      if (restartId) {
        window.clearTimeout(restartId);
        restartId = null;
      }
    }

    function updateTimer() {
      timer.textContent = formatTime(remainingSeconds);
    }

    function dismissBreak(result) {
      stopCountdown();
      stopRestart();
      demo.classList.add('break-dismissed');
      if (result === 'completed') {
        status.textContent = activeKind === 'eyes' ? 'Eye break completed' : 'Stand break completed';
      } else if (result === 'snoozed') {
        status.textContent = activeKind === 'eyes' ? 'Eye break snoozed 5m' : 'Stand break snoozed 5m';
      } else {
        status.textContent = activeKind === 'eyes' ? 'Eye break skipped' : 'Stand break skipped';
      }
      nextEye.textContent = activeKind === 'eyes' ? 'Demo restarts soon' : 'After stand break';
      nextStand.textContent = activeKind === 'stand' ? 'Demo restarts soon' : '40m 00s';
      restartId = window.setTimeout(function () {
        setKind(activeKind);
      }, 6000);
    }

    function startCountdown() {
      stopCountdown();
      updateTimer();
      countdownId = window.setInterval(function () {
        remainingSeconds -= 1;
        updateTimer();
        if (remainingSeconds <= 0) dismissBreak('completed');
      }, 1000);
    }

    function setKind(kind) {
      var current = data[kind] || data.eyes;
      stopRestart();
      activeKind = kind;
      remainingSeconds = current.seconds;
      demo.classList.remove('break-dismissed');
      demo.setAttribute('data-kind', kind);
      title.textContent = current.title;
      message.textContent = current.message;
      nextEye.textContent = current.nextEye;
      nextStand.textContent = current.nextStand;
      status.textContent = current.status;
      icon.innerHTML = current.icon === 'stand'
        ? '<path d="M16 7.5a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path d="M13.8 9.5 10 13.2l3.3 3.2-3 6.1"/><path d="M16.3 9.7l3.4 4.2 3.7 1.1"/><path d="M13.2 16.4l5.5 1.8 1.2 4.3"/><path d="M9.7 13.1 6.2 12"/>'
        : '<path d="M2.5 12C6 5.8 10.8 3 16 3s10 2.8 13.5 9c-3.5 6.2-8.3 9-13.5 9S6 18.2 2.5 12Z"/><circle cx="16" cy="12" r="4.8"/>';
      modeButtons.forEach(function (button) {
        button.classList.toggle('on', button.getAttribute('data-demo-kind') === kind);
      });
      startCountdown();
    }

    modeButtons.forEach(function (button) {
      button.addEventListener('click', function () {
        setKind(button.getAttribute('data-demo-kind'));
      });
    });

    actionButtons.forEach(function (button) {
      button.addEventListener('click', function () {
        dismissBreak(button.getAttribute('data-demo-action'));
      });
    });

    setKind('eyes');
  }

  function initSchedule() {
    var sliders = document.querySelectorAll('[data-schedule]');
    var eyeEvery = document.getElementById('eye-every');
    var eyeDuration = document.getElementById('eye-duration');
    var standEvery = document.getElementById('stand-every');
    var standDuration = document.getElementById('stand-duration');
    if (!sliders.length) return;

    function update() {
      sliders.forEach(function (slider) {
        var target = document.getElementById(slider.getAttribute('data-output'));
        if (!target) return;
        target.textContent = slider.value + slider.getAttribute('data-unit');
      });

      if (eyeEvery && eyeDuration && standEvery && standDuration) {
        eyeEvery.textContent = document.getElementById('eye-interval').value + ' min';
        eyeDuration.textContent = document.getElementById('eye-length').value + ' sec';
        standEvery.textContent = document.getElementById('stand-interval').value + ' min';
        standDuration.textContent = document.getElementById('stand-length').value + ' sec';
      }
    }

    sliders.forEach(function (slider) {
      slider.addEventListener('input', update);
    });
    update();
  }

  function boot() {
    initNav();
    initDemo();
    initSchedule();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})();
