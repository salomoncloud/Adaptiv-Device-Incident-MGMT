// Configuration - this will be updated after Terraform deployment
const API_BASE_URL = '${API_ENDPOINT_PLACEHOLDER}';

const form = document.getElementById("incidentForm");

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const data = {};
  [...form.elements].forEach(input => {
    if (input.name) {
      data[input.name] = input.value;
    }
  });

  try {
    const response = await fetch(`${API_BASE_URL}/incident`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data)
    });

    if (response.ok) {
      alert("Incident submitted successfully!");
      form.reset();
      await loadIncidentTable(); // Refresh the table
    } else {
      const errorData = await response.json();
      alert(`Error: ${errorData.error || 'Something went wrong'}`);
    }
  } catch (error) {
    console.error('Submit error:', error);
    alert("Network error. Please try again.");
  }
});

// Load all incidents on page load
window.addEventListener("DOMContentLoaded", loadIncidentTable);

async function lookupSerial() {
  const serial = document.getElementById("lookupSerial").value.trim();
  if (!serial) return alert("Please enter a serial number");

  try {
    const res = await fetch(`${API_BASE_URL}/recurring?serial_number=${encodeURIComponent(serial)}`);
    const data = await res.json();

    if (res.ok) {
      const resultBox = document.getElementById("lookupResult");
      resultBox.innerHTML = `
        <strong>${data.serial_number}</strong> has 
        <strong>${data.incident_count}</strong> incidents in the past 12 months.
      `;
    } else {
      alert(`Error: ${data.error || 'Failed to lookup serial'}`);
    }
  } catch (error) {
    console.error('Lookup error:', error);
    alert("Network error during lookup.");
  }
}

async function loadIncidentTable() {
  try {
    const res = await fetch(`${API_BASE_URL}/incidents`);
    const data = await res.json();

    if (res.ok) {
      const container = document.getElementById("incidentTableContainer");
      
      if (data.length === 0) {
        container.innerHTML = '<p>No incidents found.</p>';
        return;
      }

      const rows = data.map(i => `
        <tr>
          <td>${i.serial_number || 'N/A'}</td>
          <td>${i.detected_at || 'N/A'}</td>
          <td>${i.resolved_at || 'N/A'}</td>
          <td>${i.cause || 'N/A'}</td>
          <td>${i.resolved_by || 'N/A'}</td>
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
    } else {
      console.error('Failed to load incidents:', data);
      document.getElementById("incidentTableContainer").innerHTML = 
        '<p>Error loading incidents. Please refresh the page.</p>';
    }
  } catch (error) {
    console.error('Load table error:', error);
    document.getElementById("incidentTableContainer").innerHTML = 
      '<p>Network error loading incidents.</p>';
  }
}

function exportCSV() {
  window.open(`${API_BASE_URL}/export-csv`, "_blank");
}
