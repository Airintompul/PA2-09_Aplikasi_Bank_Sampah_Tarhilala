import { createRouter, createWebHistory } from 'vue-router';

// Konfigurasi Routes
const routes = [
    // --- AUTHENTICATION ---
    {
        path: '/login',
        name: 'Login',
        component: () => import('@/Pages/Auth/Login.vue'),
        meta: { guestOnly: true }
    },

    // --- DASHBOARD ---
    {
        path: '/dashboard',
        name: 'Dashboard',
        component: () => import('@/Pages/Admin/Dashboard.vue'),
        meta: { requiresAuth: true }
    },

    // --- PRODUCT MANAGEMENT ---
    {
        path: '/product',
        name: 'Product',
        component: () => import('@/Pages/Admin/Product/Index.vue'),
        meta: { requiresAuth: true }
    },

    // --- USER MANAGEMENT (EMPLOYEE & CUSTOMERS) ---
    {
        path: '/employee',
        name: 'Employee',
        component: () => import('@/Pages/Admin/Employee/Index.vue'),
        meta: { requiresAuth: true }
    },
    {
        path: '/customers',
        name: 'Customers',
        component: () => import('@/Pages/Admin/Customers/Index.vue'),
        meta: { requiresAuth: true }
    },

    // --- LOGISTICS (LOCATION / RUTE & JADWAL) ---
    {
        path: '/location',
        name: 'Location',
        component: () => import('@/Pages/Admin/Location/Index.vue'),
        meta: { requiresAuth: true }
    },

    // --- CONTENT & REWARD ---
    {
        path: '/library',
        name: 'Library',
        component: () => import('@/Pages/Admin/Library/Index.vue'),
        meta: { requiresAuth: true }
    },
    {
        path: '/reward',
        name: 'Reward',
        component: () => import('@/Pages/Admin/Reward/Index.vue'),
        meta: { requiresAuth: true }
    },

    // --- TRANSACTIONS (PICKUP & BILLING) ---
    {
        path: '/setoran',
        name: 'Setoran',
        component: () => import('@/Pages/Admin/Setoran/Index.vue'),
        meta: { requiresAuth: true }
    },
    {
        path: '/setoran/:id/tracking',
        name: 'SetoranTracking',
        component: () => import('@/Pages/Admin/Setoran/Tracking.vue'),
        meta: { requiresAuth: true }
    },
    {
        path: '/billing',
        name: 'Billing',
        component: () => import('@/Pages/Admin/Billing/Index.vue'),
        meta: { requiresAuth: true }
    },

    // --- MESSAGE / CHAT SYSTEM ---
    {
        path: '/messages',
        name: 'MessageIndex',
        component: () => import('@/Pages/Admin/Message/Index.vue'),
        meta: { requiresAuth: true }
    },
    {
        path: '/messages/:id',
        name: 'MessageShow',
        component: () => import('@/Pages/Admin/Message/Show.vue'),
        meta: { requiresAuth: true }
    },

    // --- REDIRECTS ---
    {
        path: '/',
        redirect: '/dashboard'
    },
    {
        path: '/:pathMatch(.*)*', // Catch-all 404
        redirect: '/dashboard'
    }
];

const router = createRouter({
    history: createWebHistory(),
    routes,
    // Agar saat pindah halaman otomatis scroll ke paling atas
    scrollBehavior() {
        return { top: 0 };
    },
});

// =====================================================
// NAVIGATION GUARD (PENGAMAN ROUTE)
// =====================================================
router.beforeEach((to, from, next) => {
    const token = localStorage.getItem('admin_token');

    // 1. Jika halaman butuh Auth tapi user belum punya Token
    if (to.meta.requiresAuth && !token) {
        next('/login');
    }
    // 2. Jika user sudah Login tapi coba akses halaman Login lagi
    else if (to.meta.guestOnly && token) {
        next('/dashboard');
    }
    // 3. Selain itu, izinkan lewat
    else {
        next();
    }
});

export default router;
