/** Keep the rendered artwork in local time without a render loop or a 3D runtime. */
export function startClock(element: HTMLElement) {
  const layers = JSON.parse(element.dataset.layers ?? '{}') as Record<string, string>;
  const slots = [...element.querySelectorAll<HTMLImageElement>('[data-slot]')];
  const poster = element.querySelector<HTMLImageElement>('.clock-poster');
  const weekday = element.querySelector<HTMLElement>('[data-weekday]');
  const time = element.querySelector<HTMLTimeElement>('[data-time]');
  const weekdayFormat = new Intl.DateTimeFormat('en', { weekday: 'short' });
  const accessibleFormat = new Intl.DateTimeFormat(undefined, { weekday: 'long', hour: 'numeric', minute: '2-digit' });
  let timeout: ReturnType<typeof setTimeout>;
  let revision = 0;
  let displayed = '';

  async function update() {
    const current = ++revision;
    const now = new Date();
    const digits = `${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}`;
    try {
      if (digits !== displayed) {
        // Decode all four first, so slow connections never show a half-updated time.
        const images = await Promise.all([...digits].map(async (digit, index) => {
          const image = new Image();
          const source = layers[`${index}-${digit}`];
          if (!source) throw new Error('Clock artwork is missing');
          image.src = source;
          await image.decode();
          return image;
        }));
        if (current !== revision || document.hidden) return;
        slots.forEach((slot, index) => { slot.src = images[index].src; });
        displayed = digits;
      }
      if (current !== revision || document.hidden) return;
      if (weekday) weekday.textContent = weekdayFormat.format(now);
      if (time) {
        time.dateTime = now.toISOString();
        time.textContent = `Your local time: ${accessibleFormat.format(now)}`;
      }
      if (poster) poster.alt = '';
      element.classList.add('is-live');
    } catch {
      if (current !== revision || document.hidden) return;
      // A missing/blocked image keeps the complete server-rendered clock visible.
      element.classList.remove('is-live');
      displayed = '';
      if (poster) poster.alt = "Sunalta's sculpted black clock, showing 09:41 in two stacked rows.";
      if (weekday) weekday.textContent = 'Mon';
      if (time) {
        time.removeAttribute('datetime');
        time.textContent = 'Clock preview: 09:41';
      }
    } finally {
      if (current === revision && !document.hidden) {
        timeout = setTimeout(update, 60_000 - Date.now() % 60_000);
      }
    }
  }

  document.addEventListener('visibilitychange', () => {
    clearTimeout(timeout);
    revision++;
    if (!document.hidden) void update();
  });
  void update();
}
