document.querySelectorAll(".burst-button").forEach((button) => {
  button.addEventListener("click", () => {
    button.classList.remove("is-spinning");
    void button.offsetWidth;
    button.classList.add("is-spinning");
  });
});

document.querySelectorAll("[data-service]").forEach((button) => {
  button.addEventListener("click", () => {
    const serviceInput = document.querySelector("#service");
    if (serviceInput) {
      serviceInput.value = button.dataset.service;
      serviceInput.focus();
    }
  });
});

document.querySelectorAll(".icon-link").forEach((link) => {
  link.addEventListener("click", (event) => {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) {
      return;
    }

    event.preventDefault();

    const destination = new URL(link.href, window.location.href);
    const rect = link.getBoundingClientRect();
    const overlay = document.createElement("div");
    overlay.className = "page-transition";
    overlay.innerHTML = `
      <div class="page-transition-mark">
        <svg aria-hidden="true"><use href="assets/hl-burst.svg#burst"></use></svg>
      </div>
    `;

    overlay.style.setProperty("--start-x", `${rect.left + rect.width / 2}px`);
    overlay.style.setProperty("--start-y", `${rect.top + rect.height / 2}px`);
    overlay.style.setProperty("--start-size", `${Math.max(rect.width, rect.height)}px`);

    document.body.appendChild(overlay);
    document.body.classList.add("is-transitioning");

    window.setTimeout(() => {
      const samePage = destination.origin === window.location.origin &&
        destination.pathname === window.location.pathname &&
        destination.hash;

      if (samePage) {
        document.querySelector(destination.hash)?.scrollIntoView({ behavior: "auto" });
        window.history.pushState(null, "", destination.hash);
        overlay.remove();
        document.body.classList.remove("is-transitioning");
        return;
      }

      window.location.href = destination.href;
    }, 1250);
  });
});

const scheduleForm = document.querySelector("#schedule-request-form");

if (scheduleForm) {
  scheduleForm.addEventListener("submit", (event) => {
    event.preventDefault();

    const data = new FormData(scheduleForm);
    const name = data.get("name") || "Website visitor";
    const service = data.get("service") || "Pressure washing";
    const body = [
      "New HL Pressure Washing schedule request",
      "",
      `Name: ${name}`,
      `Phone: ${data.get("phone") || ""}`,
      `Service address: ${data.get("address") || ""}`,
      `Service: ${service}`,
      `Preferred date: ${data.get("preferred_date") || ""}`,
      `Preferred time: ${data.get("preferred_time") || ""}`,
      "",
      "Notes:",
      data.get("notes") || "",
    ].join("\n");

    const recipients = [
      "hlpressurwashing@gmail.com",
      "landon.paul.leblanc@gmail.com",
      "moralfamily@gmail.com",
    ].join(",");

    const subject = `HL Pressure Washing request - ${service} - ${name}`;
    window.location.href = `mailto:${recipients}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
  });
}
