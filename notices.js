(function () {
  const list = document.getElementById('publicNoticeList');
  const marquee = document.getElementById('latestUpdateMarquee');
  if ((!list && !marquee) || !window.supabase || !window.SUPABASE_URL ||
      window.SUPABASE_URL.includes('PASTE_') || !window.SUPABASE_ANON_KEY ||
      window.SUPABASE_ANON_KEY.includes('PASTE_')) {
    if (list) list.innerHTML = '<div class="notice-reference-empty">Notice system সেটআপ করা হয়নি।</div>';
    if (marquee) marquee.textContent = 'Notice system সেটআপ করা হয়নি।';
    return;
  }
  const db = window.supabase.createClient(window.SUPABASE_URL, window.SUPABASE_ANON_KEY);

  function bnDate(iso) {
    const d = new Date(iso);
    return new Intl.DateTimeFormat('bn-BD', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(d);
  }

  function isImageNotice(n) {
    const type = String(n.attachment_type || '').toLowerCase();
    const name = String(n.attachment_name || '').toLowerCase();
    const url = String(n.attachment_url || '').toLowerCase();
    return type.startsWith('image/') || /\.(png|jpe?g|gif|webp|bmp|svg)(?:[?#]|$)/i.test(name) || /\.(png|jpe?g|gif|webp|bmp|svg)(?:[?#]|$)/i.test(url);
  }

  function renderReferenceBoard(data) {
    if (!list) return;
    list.replaceChildren();
    if (!data || !data.length) {
      const empty = document.createElement('div');
      empty.className = 'notice-reference-empty';
      empty.textContent = 'এই মুহূর্তে কোনো নতুন নোটিশ নেই।';
      list.append(empty);
      return;
    }

    data.slice(0, 15).forEach((n) => {
      const row = document.createElement('article');
      row.className = 'notice-reference-row';
      row.dataset.noticeId = String(n.id);
      row.setAttribute('role', 'button');
      row.setAttribute('tabindex', '0');
      row.setAttribute('aria-expanded', 'false');

      const title = document.createElement('div');
      title.className = 'notice-reference-title';
      title.textContent = n.title || 'শিরোনামহীন নোটিশ';

      const arrow = document.createElement('div');
      arrow.className = 'notice-reference-arrow';
      arrow.textContent = '→';

      const date = document.createElement('div');
      date.className = 'notice-reference-date';
      date.textContent = bnDate(n.created_at);

      const details = document.createElement('div');
      details.className = 'notice-reference-details';
      details.hidden = true;
      details.textContent = n.content || 'এই নোটিশের বিস্তারিত তথ্য পাওয়া যায়নি।';

      if (n.attachment_url) {
        const actions = document.createElement('div');
        actions.className = 'notice-reference-actions';
        const link = document.createElement('a');
        link.href = n.attachment_url;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.textContent = isImageNotice(n) ? '🖼 ছবি দেখুন / ডাউনলোড' : '📄 ফাইল দেখুন / ডাউনলোড';
        link.addEventListener('click', e => e.stopPropagation());
        actions.append(link);
        details.append(actions);
      }

      const toggle = () => {
        const opening = details.hidden;
        details.hidden = !opening;
        row.setAttribute('aria-expanded', String(opening));
        arrow.textContent = opening ? '↓' : '→';
      };
      row.addEventListener('click', toggle);
      row.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
      });

      row.append(title, arrow, date, details);
      list.append(row);
    });
  }

  function renderMarquee(data) {
    if (!marquee) return;
    marquee.replaceChildren();
    if (!data || !data.length) { marquee.textContent = 'এখন কোনো নতুন আপডেট নেই।'; return; }
    data.slice(0, 10).forEach((n) => {
      const a = document.createElement('a');
      a.href = '#publicNoticeList';
      a.textContent = (n.title || 'শিরোনামহীন নোটিশ') + '  •';
      a.style.cssText = 'display:inline-flex;align-items:center;gap:8px;white-space:nowrap;margin-right:22px;color:#fff;text-decoration:none;font-weight:700;';
      a.addEventListener('click', e => {
        e.preventDefault();
        const target = document.querySelector('[data-notice-id="' + String(n.id).replace(/[^a-zA-Z0-9_-]/g, '') + '"]');
        if (target) target.scrollIntoView({behavior:'smooth', block:'center'});
      });
      marquee.append(a);
    });
  }

  async function load() {
    const { data, error } = await db.from('notices')
      .select('id,title,content,created_at,attachment_url,attachment_name,attachment_type')
      .order('created_at', { ascending: false }).limit(20);
    if (error) {
      if (list) {
        list.replaceChildren();
        const err = document.createElement('div');
        err.className = 'notice-reference-empty';
        err.textContent = 'Notice লোড করা যায়নি। ডেটাবেসের কলাম/সেটআপ যাচাই করুন।';
        list.append(err);
      }
      if (marquee) marquee.textContent = 'Notice লোড করা যায়নি।';
      return;
    }

    // Home page and dedicated Notice Board both use the same clickable reference-style list.
    if (list) renderReferenceBoard(data);
    renderMarquee(data);
  }
  load();
  window.setInterval(load, 60000);
})();
