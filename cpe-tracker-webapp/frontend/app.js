const form = document.getElementById("incidentForm");

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const data = {};
  [...form.elements].forEach(input => {
    if (input.name) {
      data[input.name] = input.value;
    }
  });

  const response = await fetch("https://<your-api-id>.execute-api.ca-central-1.amazonaws.com/incident", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data)
  });

  if (response.ok) {
    alert("Incident submitted successfully!");
    form.reset();
  } else {
    alert("Something went wrong. Please try again.");
  }
});

// Load all incidents on page load
window.addEventListener("DOMContentLoaded", loadIncidentTable);

async function lookupSerial() {
  const serial = document.getElementById("lookupSerial").value.trim();
  if (!serial) return alert("Please enter a serial number");

  const res = await fetch(`https://<api-url>/recurring?serial_number=${serial}`);
  const data = await res.json();

  const resultBox = document.getElementById("lookupResult");
  resultBox.innerHTML = `
    <strong>${data.serial_number}</strong> has 
    <strong>${data.incident_count}</strong> incidents in the past 12 months.
  `;
}

async function loadIncidentTable() {
  const res = await fetch("https://<api-url>/incidents");
  const data = await res.json();

  const container = document.getElementById("incidentTableContainer");
  const rows = data.map(i => `
    <tr>
      <td>${i.serial_number}</td>
      <td>${i.detected_at}</td>
      <td>${i.resolved_at}</td>
      <td>${i.cause}</td>
      <td>${i.resolved_by}</td>
    </tr>
  `).join("");

  container.innerHTML = `
    <table>
      <thead>
        <tr>
          <th>Serial</th>
          <th>Detected At</th>
          <th>Resolved At</th>
          <th>Cause</th>
          <th>Resolved By</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `;
}

function exportCSV() {
  window.open("https://<api-url>/export-csv", "_blank");
}
