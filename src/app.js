/* STUDIO — interactions: 3D hero, tilt, lightbox, hover-play, reveals */
(() => {
  'use strict';
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------- 3D HERO (Three.js) ---------- */
  function initHero() {
    const canvas = document.getElementById('hero-canvas');
    if (!canvas || typeof THREE === 'undefined' || reduce) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(60, 1, 0.1, 100);
    camera.position.z = 4.2;

    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

    // Distorted icosahedron — wireframe core + particle shell
    const geo = new THREE.IcosahedronGeometry(1.5, 4);
    const basePos = geo.attributes.position.array.slice();

    const mat = new THREE.MeshBasicMaterial({ color: 0xff3d2e, wireframe: true, transparent: true, opacity: 0.55 });
    const mesh = new THREE.Mesh(geo, mat);
    scene.add(mesh);

    // Particle shell
    const pGeo = new THREE.IcosahedronGeometry(1.85, 5);
    const pMat = new THREE.PointsMaterial({ color: 0xffffff, size: 0.012, transparent: true, opacity: 0.7 });
    const pts = new THREE.Points(pGeo, pMat);
    scene.add(pts);

    // Outer faint ring of points
    const ringGeo = new THREE.BufferGeometry();
    const N = 1400, arr = new Float32Array(N * 3);
    for (let i = 0; i < N; i++) {
      const r = 2.6 + Math.random() * 1.8;
      const t = Math.random() * Math.PI * 2;
      const p = Math.acos(2 * Math.random() - 1);
      arr[i*3]   = r * Math.sin(p) * Math.cos(t);
      arr[i*3+1] = r * Math.sin(p) * Math.sin(t);
      arr[i*3+2] = r * Math.cos(p);
    }
    ringGeo.setAttribute('position', new THREE.BufferAttribute(arr, 3));
    const ring = new THREE.Points(ringGeo, new THREE.PointsMaterial({ color: 0xffd84d, size: 0.014, transparent: true, opacity: 0.35 }));
    scene.add(ring);

    let mx = 0, my = 0, tmx = 0, tmy = 0;
    window.addEventListener('pointermove', e => {
      tmx = (e.clientX / window.innerWidth - 0.5) * 2;
      tmy = (e.clientY / window.innerHeight - 0.5) * 2;
    });

    function resize() {
      const w = canvas.clientWidth, h = canvas.clientHeight;
      if (canvas.width !== w || canvas.height !== h) {
        renderer.setSize(w, h, false);
        camera.aspect = w / h; camera.updateProjectionMatrix();
      }
    }

    const pos = geo.attributes.position;
    let t = 0;
    function animate() {
      requestAnimationFrame(animate);
      resize();
      t += 0.01;
      mx += (tmx - mx) * 0.05; my += (tmy - my) * 0.05;

      // breathing distortion
      for (let i = 0; i < pos.count; i++) {
        const ix = i*3;
        const x = basePos[ix], y = basePos[ix+1], z = basePos[ix+2];
        const n = Math.sin(x*2 + t) * Math.cos(y*2 + t) * Math.sin(z*2 + t*0.7);
        const s = 1 + n * 0.12;
        pos.array[ix] = x*s; pos.array[ix+1] = y*s; pos.array[ix+2] = z*s;
      }
      pos.needsUpdate = true;

      mesh.rotation.y += 0.002; mesh.rotation.x += 0.001;
      mesh.rotation.y += mx * 0.01; mesh.rotation.x += my * 0.01;
      pts.rotation.copy(mesh.rotation);
      ring.rotation.y -= 0.0008; ring.rotation.x = my * 0.2;

      camera.position.x += (mx * 0.6 - camera.position.x) * 0.05;
      camera.position.y += (-my * 0.6 - camera.position.y) * 0.05;
      camera.lookAt(scene.position);

      renderer.render(scene, camera);
    }
    animate();
  }

  /* ---------- CARD TILT (3D) ---------- */
  function initTilt() {
    if (reduce) return;
    document.querySelectorAll('.tilt').forEach(el => {
      el.addEventListener('pointermove', e => {
        const r = el.getBoundingClientRect();
        const px = (e.clientX - r.left) / r.width - 0.5;
        const py = (e.clientY - r.top) / r.height - 0.5;
        el.style.transform = `perspective(900px) rotateY(${px*7}deg) rotateX(${-py*7}deg) scale(1.01)`;
      });
      el.addEventListener('pointerleave', () => { el.style.transform = ''; });
    });
  }

  /* ---------- HOVER PLAY LOOPS ---------- */
  function initHoverPlay() {
    document.querySelectorAll('.work-media video').forEach(v => {
      const card = v.closest('.work-media');
      const play = () => { if (v.preload === 'none') v.preload = 'auto'; v.play().catch(()=>{}); };
      const stop = () => { v.pause(); };
      card.addEventListener('pointerenter', play);
      card.addEventListener('pointerleave', stop);
      // On touch / mobile: autoplay when in view
      if (window.matchMedia('(hover:none)').matches) {
        const io = new IntersectionObserver(es => es.forEach(en => en.isIntersecting ? play() : stop()), { threshold: 0.4 });
        io.observe(card);
      }
    });
  }

  /* ---------- LIGHTBOX ---------- */
  function initLightbox() {
    const lb = document.getElementById('lb');
    const lbVideo = document.getElementById('lbVideo');
    const lbCap = document.getElementById('lbCap');
    const close = () => { lb.classList.remove('open'); lbVideo.pause(); lbVideo.removeAttribute('src'); lbVideo.load(); document.body.style.overflow=''; };
    const open = (src, cap) => {
      lbVideo.src = src; lbCap.textContent = cap || '';
      lb.classList.add('open'); document.body.style.overflow='hidden';
      lbVideo.play().catch(()=>{});
    };
    document.querySelectorAll('[data-video]').forEach(el => {
      el.addEventListener('click', () => open(el.dataset.video, el.dataset.cap));
    });
    document.getElementById('lbClose').addEventListener('click', close);
    lb.addEventListener('click', e => { if (e.target === lb) close(); });
    document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });
  }

  /* ---------- SCROLL REVEAL ---------- */
  function initReveal() {
    const els = document.querySelectorAll('.reveal');
    if (reduce) { els.forEach(e=>e.classList.add('in')); return; }
    const io = new IntersectionObserver(es => es.forEach(en => {
      if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
    }), { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });
    els.forEach(e => io.observe(e));
  }

  /* ---------- NAV BG ON SCROLL ---------- */
  function initNav() {
    const nav = document.querySelector('nav');
    const onScroll = () => {
      if (window.scrollY > window.innerHeight * 0.85) {
        nav.style.mixBlendMode = 'normal';
        nav.style.background = 'rgba(10,10,11,.8)';
        nav.style.backdropFilter = 'blur(12px)';
        nav.style.borderBottom = '1px solid var(--border)';
      } else {
        nav.style.mixBlendMode = 'difference';
        nav.style.background = 'none';
        nav.style.backdropFilter = 'none';
        nav.style.borderBottom = 'none';
      }
    };
    window.addEventListener('scroll', onScroll, { passive: true }); onScroll();
  }

  document.addEventListener('DOMContentLoaded', () => {
    initHero(); initTilt(); initHoverPlay(); initLightbox(); initReveal(); initNav();
  });
})();
