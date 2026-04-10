import Vue from 'vue';
import VueRouter from 'vue-router';
import Home from '@/views/Home.vue';
import Device from '@/views/Device.vue';
import About from '@/views/About.vue';
import Backup from '@/views/Backup.vue';

Vue.use(VueRouter);

const router = new VueRouter({
    routes: [
        {
            path: '/',
            component: Home,
            meta: {
                keepAlive: true,
            },
        },
        {
            path: '/device',
            component: Device,
            meta: {
                keepAlive: true,
            },
        },
        {
            path: '/about',
            component: About,
            meta: {
                keepAlive: true,
            },
        },
        {
            path: '/backup',
            component: Backup,
            meta: {
                keepAlive: true,
            },
        },
    ],
});

export default router;
