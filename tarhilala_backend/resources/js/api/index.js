import axios from 'axios';

const api = axios.create({
    baseURL: '/api/admin',
});

// INSTANCE BARU: Khusus untuk Finance Service (Port 8001)
export const financeApi = axios.create({
    baseURL: 'http://127.0.0.1:8001/api/admin', // Arahkan ke Port 8001
});

// Menempelkan token ke setiap request
api.interceptors.request.use(config => {
    // Ambil token dari browser
    const token = localStorage.getItem('admin_token');
    if (token) {
        // PENTING: Harus pakai 'Bearer ' (ada spasinya)
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Tangani jika token mati (401)
api.interceptors.response.use(
    res => res,
    error => {
        if (error.response && error.response.status === 401) {
            console.log("Token tidak valid, melempar ke login...");
            localStorage.removeItem('admin_token');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

export default api;
