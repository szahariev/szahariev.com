(() => {
  const root = document.documentElement;
  const toggle = document.querySelector("[data-theme-toggle]");
  const themeColor = document.querySelector("[data-theme-color]");
  const systemTheme = window.matchMedia("(prefers-color-scheme: light)");

  if (!toggle) return;

  const currentTheme = () =>
    root.dataset.theme || (systemTheme.matches ? "light" : "dark");

  const render = () => {
    const current = currentTheme();
    const next = current === "dark" ? "light" : "dark";
    const label = toggle.querySelector("[data-theme-label]");
    const icon = toggle.querySelector("[data-theme-icon]");
    const accessibleLabel = toggle.dataset[
      next === "light" ? "switchToLight" : "switchToDark"
    ];

    label.textContent = toggle.dataset[next + "Label"];
    icon.textContent = next === "light" ? "☀" : "☾";
    toggle.setAttribute("aria-label", accessibleLabel);
    toggle.title = accessibleLabel;

    if (themeColor) {
      themeColor.content = themeColor.dataset[current];
    }
  };

  toggle.addEventListener("click", () => {
    const next = currentTheme() === "dark" ? "light" : "dark";
    root.dataset.theme = next;
    try {
      localStorage.setItem("theme", next);
    } catch (_) {}
    render();
  });

  systemTheme.addEventListener("change", () => {
    if (!root.dataset.theme) render();
  });

  render();
})();
