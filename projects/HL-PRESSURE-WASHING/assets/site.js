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
