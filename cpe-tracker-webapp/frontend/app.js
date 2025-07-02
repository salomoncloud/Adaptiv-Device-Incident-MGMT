// Enhanced app.js with Cognito authentication
const API_BASE_URL = "${API_ENDPOINT_PLACEHOLDER}";

// Cognito configuration - these values come from Terraform outputs
const COGNITO_CONFIG = {
    userPoolId: '${COGNITO_USER_POOL_ID}',
    clientId: '${COGNITO_CLIENT_ID}',
    region: 'ca-central-1'
};

// Authentication state
let currentUser = null;
let authToken = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', async () => {
    // Check if user is already logged in
    const token = localStorage.getItem('authToken');
    const userInfo = localStorage.getItem('userInfo');
    
    if (token && userInfo) {
        authToken = token;
        currentUser = JSON.parse(userInfo);
        showMainApp();
        await loadIncidentTable();
    } else {
        showLoginForm();
    }
});

// Show/hide UI elements based on auth state
function showMainApp() {
    document.getElementById('loginSection').style.display = 'none';
    document.getElementById('mainApp').style.display = 'block';
    document.getElementById('userInfo').textContent = `Logged in as: ${currentUser.username}`;
}

function showLoginForm() {
    document.getElementById('loginSection').style.display = 'block';
    document.getElementById('mainApp').style.display = 'none';
}

// Login function
async function login() {
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    
    if (!username || !password) {
        alert('Please enter both username and password');
        return;
    }
    
    try {
        // This is a simplified version - in production, use AWS Amplify or AWS SDK
        const loginData = {
            AuthFlow: 'USER_PASSWORD_AUTH',
            ClientId: COGNITO_CONFIG.clientId,
            AuthParameters: {
                USERNAME: username,
                PASSWORD: password
            }
        };
        
        // Call Cognito InitiateAuth API (you'd need to implement this properly)
        const response = await authenticateUser(loginData);
        
        if (response.AuthenticationResult) {
            authToken = response.AuthenticationResult.AccessToken;
            currentUser = { username: username };
            
            // Store in localStorage for persistence
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('userInfo', JSON.stringify(currentUser));
            
            showMainApp();
            await loadIncidentTable();
        }
    } catch (error) {
        console.error('Login error:', error);
        alert('Login failed. Please check your credentials.');
    }
}

// Logout function
function logout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('userInfo');
    showLoginForm();
}

// Enhanced API calls with authentication
async function authenticatedFetch(url, options = {}) {
    if (!authToken) {
        throw new Error('Not authenticated');
    }
    
    const headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
        ...options.headers
    };
    
    return fetch(url, { ...options, headers });
}

// Updated form submission with auth
const form = document.getElementById("incidentForm");
form.addEventListener("submit", async (e) => {
    e.preventDefault();

    if (!authToken) {
        alert('Please log in to submit incidents');
        return;
    }

    const data = {};
    [...form.elements].forEach(input => {
        if (input.name) {
            data[input.name] = input.value;
        }
    });

    try {
        const response = await authenticatedFetch(`${API_BASE_URL}/incident`, {
            method: "POST",
            body: JSON.stringify(data)
        });

        if (response.ok) {
            alert("Incident submitted successfully!");
            form.reset();
            await loadIncidentTable();
        } else {
            const errorData = await response.json();
            alert(`Error: ${errorData.error || "Something went wrong"}`);
        }
    } catch (error) {
        console.error("Submit error:", error);
        alert("Network error. Please try again.");
    }
});

// Updated lookup function with auth
async function lookupSerial() {
    if (!authToken) {
        alert('Please log in to lookup serial numbers');
        return;
    }

    const serial = document.getElementById("lookupSerial").value.trim();
    if (!serial) return alert("Please enter a serial number");

    try {
        const res = await authenticatedFetch(
            `${API_BASE_URL}/recurring?serial_number=${encodeURIComponent(serial)}`
        );
        const data = await res.json();

        if (res.ok) {
            const resultBox = document.getElementById("lookupResult");
            resultBox.innerHTML = `
                <strong>${data.serial_number}</strong> has 
                <strong>${data.incident_count}</strong> incidents in the past 12 months.
            `;
        } else {
            alert(`Error: ${data.error || "Failed to lookup serial"}`);
        }
    } catch (error) {
        console.error("Lookup error:", error);
        alert("Network error during lookup.");
    }
}

// Updated table loading with auth
async function loadIncidentTable() {
    if (!authToken) return;

    try {
        const res = await authenticatedFetch(`${API_BASE_URL}/incidents`);
        const data = await res.json();

        if (res.ok) {
            const container = document.getElementById("incidentTableContainer");
            
            if (data.length === 0) {
                container.innerHTML = "<p>No incidents found.</p>";
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
            console.error("Failed to load incidents:", data);
            document.getElementById("incidentTableContainer").innerHTML = 
                "<p>Error loading incidents. Please refresh the page.</p>";
        }
    } catch (error) {
        console.error("Load table error:", error);
        document.getElementById("incidentTableContainer").innerHTML = 
            "<p>Network error loading incidents.</p>";
    }
}

function exportCSV() {
    if (!authToken) {
        alert('Please log in to export data');
        return;
    }
    window.open(`${API_BASE_URL}/export-csv`, "_blank");
}

// Placeholder function for actual Cognito authentication
// In production, use AWS Amplify or AWS SDK for JavaScript
async function authenticateUser(loginData) {
    // This would make an actual call to AWS Cognito
    // For now, this is a placeholder that would need proper implementation
    throw new Error('Cognito authentication not fully implemented');
}
  window.open(`$${API_BASE_URL}/export-csv`, "_blank");
}
