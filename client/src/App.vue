<template>
    <v-app>
        <v-navigation-drawer
            v-model="drawer"
            temporary
            app
        >
            <v-list>
                <v-list-item link href="#/">
                    <v-list-item-action>
                        <v-icon>{{mdiContentPaste}}</v-icon>
                    </v-list-item-action>
                    <v-list-item-content>
                        <v-list-item-title>剪贴板</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>
                <v-list-item link href="#/device">
                    <v-list-item-action>
                        <v-icon>{{mdiDevices}}</v-icon>
                    </v-list-item-action>
                    <v-list-item-content>
                        <v-list-item-title>设备列表</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>
                <v-menu
                    offset-x
                    transition="slide-x-transition"
                    open-on-click
                    open-on-hover
                    :close-on-content-click="false"
                >
                    <template v-slot:activator="{on}">
                        <v-list-item link v-on="on">
                            <v-list-item-action>
                                <v-icon>{{mdiBrightness4}}</v-icon>
                            </v-list-item-action>
                            <v-list-item-content>
                                <v-list-item-title>深色模式</v-list-item-title>
                            </v-list-item-content>
                        </v-list-item>
                    </template>
                    <v-list two-line>
                        <v-list-item-group v-model="$root.dark" color="primary" mandatory>
                            <v-list-item link value="time">
                                <v-list-item-content>
                                    <v-list-item-title>根据时间切换</v-list-item-title>
                                    <v-list-item-subtitle>在 19:00 到次日 7:00 期间启用</v-list-item-subtitle>
                                </v-list-item-content>
                            </v-list-item>
                            <v-list-item link value="prefer">
                                <v-list-item-content>
                                    <v-list-item-title>根据系统设置切换</v-list-item-title>
                                    <v-list-item-subtitle>使用 <code>prefers-color-scheme</code> 检测</v-list-item-subtitle>
                                </v-list-item-content>
                            </v-list-item>
                            <v-list-item link value="enable">
                                <v-list-item-content>
                                    <v-list-item-title>保持启用</v-list-item-title>
                                </v-list-item-content>
                            </v-list-item>
                            <v-list-item link value="disable">
                                <v-list-item-content>
                                    <v-list-item-title>保持禁用</v-list-item-title>
                                </v-list-item-content>
                            </v-list-item>
                        </v-list-item-group>
                    </v-list>
                </v-menu>

                <!-- customize primary color -->
                <v-list-item link @click="colorDialog = true; drawer=false;">
                    <v-list-item-action>
                        <v-icon>{{mdiPalette}}</v-icon>
                    </v-list-item-action>
                    <v-list-item-content>
                        <v-list-item-title>更改主题色</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>

                <v-list-item link href="#/backup">
                    <v-list-item-action>
                        <v-icon>{{mdiContentSave}}</v-icon>
                    </v-list-item-action>
                    <v-list-item-content>
                        <v-list-item-title>数据备份与设置</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>

                <v-list-item link href="#/about">
                    <v-list-item-action>
                        <v-icon>{{mdiInformation}}</v-icon>
                    </v-list-item-action>
                    <v-list-item-content>
                        <v-list-item-title>关于</v-list-item-title>
                    </v-list-item-content>
                </v-list-item>
            </v-list>
        </v-navigation-drawer>

        <v-app-bar
            app
            color="primary"
            dark
        >
            <v-app-bar-nav-icon @click.stop="drawer = !drawer" />
            <v-toolbar-title>云剪贴板</v-toolbar-title>
            <v-spacer></v-spacer>
            <v-tooltip left>
                <template v-slot:activator="{ on }">
                    <v-btn icon v-on="on" @click="clearAllDialog = true">
                        <v-icon>{{mdiNotificationClearAll}}</v-icon>
                    </v-btn>
                </template>
                <span>清空剪贴板</span>
            </v-tooltip>
            <v-tooltip left>
                <template v-slot:activator="{ on }">
                    <v-btn icon v-on="on" @click="if (!$root.websocket && !$root.websocketConnecting) {$root.retry = 0; $root.connect();}">
                        <v-icon v-if="$root.websocket">{{mdiLanConnect}}</v-icon>
                        <v-icon v-else-if="$root.websocketConnecting">{{mdiLanPending}}</v-icon>
                        <v-icon v-else>{{mdiLanDisconnect}}</v-icon>
                    </v-btn>
                </template>
                <span v-if="$root.websocket">已连接</span>
                <span v-else-if="$root.websocketConnecting">连接中</span>
                <span v-else>未连接，点击重连</span>
            </v-tooltip>
        </v-app-bar>

        <v-main>
            <template v-if="$route.meta.keepAlive">
                <keep-alive><router-view /></keep-alive>
            </template>
            <router-view v-else />
        </v-main>

        <v-dialog v-model="colorDialog" max-width="300" hide-overlay>
            <v-card>
                <v-card-title>选择主题颜色</v-card-title>
                <v-card-text>
                    <v-color-picker v-if="$vuetify.theme.dark" v-model="$vuetify.theme.themes.dark.primary " show-swatches hide-inputs></v-color-picker>
                    <v-color-picker v-else                     v-model="$vuetify.theme.themes.light.primary" show-swatches hide-inputs></v-color-picker>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn color="primary" text @click="colorDialog = false">确定</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="$root.authCodeDialog" persistent max-width="360">
            <v-card>
                <v-card-title class="headline">需要认证</v-card-title>
                <v-card-text>
                    <p>这个剪贴板服务并不是公开的，请输入密码以继续连接。</p>
                    <v-text-field v-model="$root.authCode" label="密码"></v-text-field>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn
                        color="primary darken-1"
                        text
                        @click="
                            $root.authCodeDialog = false;
                            $root.connect();
                        "
                    >提交</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <v-dialog v-model="clearAllDialog" max-width="360">
            <v-card>
                <v-card-title class="headline">清空剪贴板</v-card-title>
                <v-card-text>
                    <p>是否要清空当前所有剪贴板内容？</p>
                </v-card-text>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn
                        color="primary darken-1"
                        text
                        @click="clearAllDialog = false"
                    >取消</v-btn>
                    <v-btn
                        color="primary darken-1"
                        text
                        @click="clearAllDialog = false; clearAll()"
                    >确定</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </v-app>
</template>

<style scoped>
.v-navigation-drawer >>> .v-navigation-drawer__border {
    pointer-events: none;
}
</style>

<script>
import {
    mdiContentPaste,
    mdiDevices,
    mdiInformation,
    mdiLanConnect,
    mdiLanDisconnect,
    mdiLanPending,
    mdiBrightness4,
    mdiPalette,
    mdiNotificationClearAll,
    mdiContentSave,
} from '@mdi/js';

export default {
    data() {
        return {
            drawer: false,
            colorDialog: false,
            clearAllDialog: false,
            mdiContentPaste,
            mdiDevices,
            mdiInformation,
            mdiLanConnect,
            mdiLanDisconnect,
            mdiLanPending,
            mdiBrightness4,
            mdiPalette,
            mdiNotificationClearAll,
            mdiContentSave,
            navigator,
        };
    },
    methods: {
        async clearAll() {
            try {
                const files = this.$root.received.filter(e => e.type === 'file');
                await this.$http.delete('revoke/all');
                for (const file of files) {
                    await this.$http.delete(`file/${file.cache}`);
                }
            } catch (error) {
                console.log(error);
                if (error.response && error.response.data.msg) {
                    this.$toast(`清空剪贴板失败：${error.response.data.msg}`);
                } else {
                    this.$toast('清空剪贴板失败');
                }
            }
        },
    },
    mounted() {
        // primary color <==> localStorage
        // theme colors <== localStorage
        const darkPrimary = localStorage.getItem('darkPrimary');
        const lightPrimary = localStorage.getItem('lightPrimary');
        if (darkPrimary) {
            this.$vuetify.theme.themes.dark.primary = darkPrimary;
        }
        if (lightPrimary) {
            this.$vuetify.theme.themes.light.primary = lightPrimary;
        }

        // theme colors ==> localStorage
        this.$watch('$vuetify.theme.themes.dark.primary', (newVal) => {
            localStorage.setItem('darkPrimary', newVal);
        });
        this.$watch('$vuetify.theme.themes.light.primary', (newVal) => {
            localStorage.setItem('lightPrimary', newVal);
        });
    },
};


</script>
