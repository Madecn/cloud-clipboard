<template>
    <v-container fill-height>
        <v-row justify="center" align="center" class="pa-3">
            <div class="text-center" style="max-width:600px;width:100%;">
                <p class="headline my-4">数据备份与参数设置</p>
                <p class="caption text--secondary mb-4">
                    导出/导入包括当前所有文本记录和尚未过期的文件内容。导入备份会<strong>覆盖</strong>服务器当前的数据。
                    需要在启用了鉴权的服务器上使用，并使用管理员口令登录后操作。
                </p>

                <v-divider class="my-4"></v-divider>
                <p class="subtitle-1 mb-2">数据备份</p>
                <div class="my-2">
                    <v-btn color="primary" class="ma-2" @click="exportBackup" :loading="exporting" :disabled="exporting || importing">
                        导出所有数据
                    </v-btn>
                    <v-btn color="primary" class="ma-2" @click="$refs.importInput.click()" :loading="importing" :disabled="exporting || importing">
                        导入备份
                    </v-btn>
                    <input
                        ref="importInput"
                        type="file"
                        accept="application/json"
                        style="display:none"
                        @change="onImportFileChange"
                    >
                </div>

                <v-divider class="my-6"></v-divider>
                <p class="subtitle-1 mb-2">参数设置</p>
                <p class="caption text--secondary mb-4">
                    在此调整文本长度、文件大小和文件保留时间的限制。默认值来自当前服务器配置。
                </p>

                <v-form ref="form" v-model="formValid" lazy-validation>
                    <v-text-field
                        v-model.number="textLimit"
                        type="number"
                        label="文本长度限制（字符）"
                        :rules="[v => v > 0 || '必须大于 0']"
                        :suffix="'当前：' + ($root.config.text.limit || 0) + ' 字'"
                    ></v-text-field>
                    <v-text-field
                        v-model.number="fileLimitMB"
                        type="number"
                        label="文件大小限制（MB）"
                        :rules="[v => v > 0 || '必须大于 0']"
                        :suffix="'当前：' + prettyFileSize($root.config.file.limit || 0)"
                    ></v-text-field>
                    <v-text-field
                        v-model.number="fileExpireDays"
                        type="number"
                        label="文件保留时间（天）"
                        :rules="[v => v > 0 || '必须大于 0']"
                        :suffix="'当前：' + formatDays($root.config.file.expire || 0)"
                    ></v-text-field>
                    <div class="text-right mt-4">
                        <v-btn
                            color="primary"
                            :loading="saving"
                            :disabled="!formValid || saving"
                            @click="saveConfig"
                        >保存配置</v-btn>
                    </div>
                </v-form>
            </div>
        </v-row>
    </v-container>
</template>

<script>
import {
    prettyFileSize,
} from '@/util.js';

export default {
    data() {
        return {
            exporting: false,
            importing: false,
            saving: false,
            formValid: true,
            textLimit: 0,
            fileLimitMB: 0,
            fileExpireDays: 0,
            prettyFileSize,
        };
    },
    methods: {
        initFromConfig() {
            const cfg = this.$root.config;
            if (!cfg) return;
            if (!this.textLimit) {
                this.textLimit = cfg.text && cfg.text.limit ? cfg.text.limit : 0;
            }
            if (!this.fileLimitMB && cfg.file && cfg.file.limit) {
                this.fileLimitMB = Math.round(cfg.file.limit / 1024 / 1024);
            }
            if (!this.fileExpireDays && cfg.file && cfg.file.expire) {
                this.fileExpireDays = Math.round(cfg.file.expire / 86400);
            }
        },
        formatDays(seconds) {
            if (!seconds) return '未设置';
            const days = seconds / 86400;
            if (days >= 1) {
                return days.toFixed(1).replace(/\.0$/, '') + ' 天';
            }
            const hours = seconds / 3600;
            return hours.toFixed(1).replace(/\.0$/, '') + ' 小时';
        },
        async exportBackup() {
            try {
                this.exporting = true;
                const response = await this.$http.get('backup', {
                    responseType: 'blob',
                });
                const blob = new Blob([response.data], { type: 'application/json;charset=utf-8' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                const now = new Date();
                const ts = now.toISOString().replace(/[:.]/g, '-');
                a.href = url;
                a.download = `cloud-clipboard-backup-${ts}.json`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);
                this.$toast && this.$toast('导出成功');
            } catch (err) {
                console.error(err);
                this.$toast && this.$toast.error('导出失败，请检查网络或权限');
            } finally {
                this.exporting = false;
            }
        },
        onImportFileChange(e) {
            const file = e.target.files[0];
            if (!file) return;
            const reader = new FileReader();
            reader.onload = async () => {
                try {
                    this.importing = true;
                    const text = reader.result;
                    const json = JSON.parse(text);
                    await this.$http.post('backup', json, {
                        headers: {
                            'Content-Type': 'application/json',
                        },
                    });
                    this.$toast && this.$toast('导入成功，正在刷新数据……');
                    if (this.$root && typeof this.$root.disconnect === 'function' && typeof this.$root.connect === 'function') {
                        this.$root.disconnect();
                        this.$root.received = [];
                        this.$root.device = [];
                        this.$root.connect();
                    } else {
                        location.reload();
                    }
                } catch (err) {
                    console.error(err);
                    this.$toast && this.$toast.error('导入失败，备份文件格式可能不正确');
                } finally {
                    this.importing = false;
                    e.target.value = '';
                }
            };
            reader.readAsText(file, 'utf-8');
        },
        async saveConfig() {
            if (!this.$refs.form || !this.$refs.form.validate()) return;
            try {
                this.saving = true;
                const payload = {
                    text: {
                        limit: Number(this.textLimit),
                    },
                    file: {
                        limit: Number(this.fileLimitMB) * 1024 * 1024,
                        expire: Number(this.fileExpireDays) * 86400,
                    },
                };
                const response = await this.$http.post('config', payload, {
                    headers: {
                        'Content-Type': 'application/json',
                    },
                });
                const cfg = response.data && response.data.result ? response.data.result : null;
                if (cfg) {
                    this.$root.config = cfg;
                }
                this.$toast && this.$toast('配置已保存');
            } catch (err) {
                console.error(err);
                this.$toast && this.$toast.error('保存配置失败');
            } finally {
                this.saving = false;
            }
        },
    },
    watch: {
        '$root.config': {
            handler() {
                this.initFromConfig();
            },
            deep: true,
        },
    },
    mounted() {
        this.initFromConfig();
    },
};
</script>


