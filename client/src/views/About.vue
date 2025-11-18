<template>
    <v-container fill-height>
        <v-row justify="center" align="center" class="pa-3">
            <div class="text-center">
                <p class="headline my-4">Cloud Clipboard {{$root.config.version}}</p>
                <p>在局域网内互传纯文本和文件的云剪贴板<br>即开即用的网页版，无须安装 APP</p>
                <p><a href="https://github.com/TransparentLC/cloud-clipboard" target="_blank"><img src="https://img.shields.io/github/stars/TransparentLC/cloud-clipboard.svg?style=social"></a></p>
                <p class="text--secondary"><small>如果你觉得这个工具很好用，欢迎<a href="https://i.akarin.dev/donate/" target="_blank">捐赠支持开发者</a>～</small></p>

                <v-divider class="my-6"></v-divider>
                <p class="subtitle-1 mb-4">数据备份</p>
                <p class="caption text--secondary mb-4">
                    导出/导入包括当前所有文本记录和尚未过期的文件内容。导入备份会<strong>覆盖</strong>服务器当前的数据。
                </p>
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
                <p class="caption text--secondary">
                    需要在启用了鉴权的服务器上使用，并使用管理员口令登录后操作。
                </p>
            </div>
        </v-row>
    </v-container>
</template>

<script>
export default {
    data() {
        return {
            exporting: false,
            importing: false,
        };
    },
    methods: {
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
    },
}
</script>