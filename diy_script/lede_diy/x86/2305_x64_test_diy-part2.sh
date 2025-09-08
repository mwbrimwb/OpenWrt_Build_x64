#!/bin/bash
#===============================================
# Description: 2305_x64_test DIY script part 2
# File name: 2305_x64_test_diy-part2.sh
# Lisence: MIT
# By: GXNAS
#===============================================

echo "开始 DIY2 配置……"
echo "========================="
build_date=$(TZ=Asia/Shanghai date "+%Y.%m.%d")

# Git稀疏克隆，只克隆指定目录到本地
chmod +x $GITHUB_WORKSPACE/diy_script/function.sh
source $GITHUB_WORKSPACE/diy_script/function.sh
rm -rf package/custom; mkdir package/custom

# 修改主机名字
sed -i "/uci commit system/i\uci set system.@system[0].hostname='OpenWrt-GXNAS'" package/lean/default-settings/files/zzz-default-settings
sed -i "s/hostname='.*'/hostname='OpenWrt-GXNAS'/g" ./package/base-files/files/bin/config_generate

# 修改默认IP
sed -i 's/192.168.1.1/192.168.1.11/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.1.11/g' package/base-files/luci2/bin/config_generate

# 设置密码为空
sed -i '/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./d' package/lean/default-settings/files/zzz-default-settings

# 调整 x86 型号显示
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# samba解除root限制
sed -i 's/invalid users = root/#&/g' feeds/packages/net/samba4/files/smb.conf.template

# 删除 coremark 定时
sed -i '/\* \* \* \/etc\/coremark.sh/d' feeds/packages/utils/coremark/*

# 修改主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/Bootstrap theme/Argon theme/g' feeds/luci/collections/*/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/*/Makefile

# 最大连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 替换curl
curl_ver=$(grep -i "PKG_VERSION:=" feeds/packages/net/curl/Makefile | awk -F'=' '{print $2}')
if [ "$curl_ver" != "8.9.1" ]; then
    echo "当前 curl 版本是: $curl_ver,开始替换......"
    rm -rf feeds/packages/net/curl
    cp -rf $GITHUB_WORKSPACE/personal/curl feeds/packages/net/curl
fi

# 删除冲突包
rm -rf feeds/kenzok8/v2ray-plugin
rm -rf feeds/kenzok8/open-app-filter
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/adguardhome

# 合并额外包
merge_package master https://github.com/xiangfeidexiaohuo/extra-ipk package/custom luci-app-adguardhome patch/wall-luci/lua-maxminddb patch/wall-luci/luci-app-vssr

# luci-app-turboacc
rm -rf feeds/luci/applications/luci-app-turboacc
git clone https://github.com/chenmozhijin/turboacc
mkdir -p package/luci-app-turboacc
mv turboacc/luci-app-turboacc package/luci-app-turboacc
rm -rf turboacc

# luci-app-adbyby-plus
rm -rf feeds/packages/net/adbyby-plus
rm -rf feeds/luci/applications/luci-app-adbyby-plus
git clone https://github.com/kiddin9/kwrt-packages
mkdir -p package/luci-app-adbyby-plus
mv kwrt-packages/luci-app-adbyby-plus package/luci-app-adbyby-plus
rm -rf kwrt-packages

# frpc frps
rm -rf feeds/luci/applications/{luci-app-frpc,luci-app-frps,luci-app-hd-idle,luci-app-adblock,luci-app-filebrowser}
merge_package master https://github.com/immortalwrt/luci package/custom applications/luci-app-openlist applications/luci-app-filebrowser applications/luci-app-syncdial applications/luci-app-eqos applications/luci-app-nps applications/luci-app-nfs applications/luci-app-frpc applications/luci-app-frps applications/luci-app-hd-idle applications/luci-app-adblock applications/luci-app-socat

# luci-app-bandix
git clone --depth=1 https://github.com/timsaya/luci-app-bandix.git package/luci-app-bandix

# nikki
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki.git package/luci-app-nikki

# mosdns
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# passwall
rm -rf feeds/luci/applications/luci-app-passwall
merge_package main https://github.com/xiaorouji/openwrt-passwall package/custom luci-app-passwall

# openclash
rm -rf feeds/luci/applications/luci-app-openclash
merge_package master https://github.com/vernesong/OpenClash package/custom luci-app-openclash
pushd package/custom/luci-app-openclash/tools/po2lmo
make && sudo make install
popd

# argon主题
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 -b js https://github.com/lwb1978/luci-theme-kucat package/luci-theme-kucat
cp -f $GITHUB_WORKSPACE/personal/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# 显示编译时间
sed -i "s/DISTRIB_REVISION='R[0-9]\+\.[0-9]\+\.[0-9]\+'/DISTRIB_REVISION='@R$build_date'/g" package/lean/default-settings/files/zzz-default-settings
sed -i 's/LEDE/OpenWrt_2305_x64_测试版 by GXNAS build/g' package/lean/default-settings/files/zzz-default-settings

# 修改右下角脚本版本信息
echo "修改前的package/luci-theme-argon/ucode/template/themes/argon/footer.ut的内容是："
cat package/luci-theme-argon/ucode/template/themes/argon/footer.ut
echo "修改前的package/luci-theme-argon/ucode/template/themes/argon/footer.ut内容显示完毕！"
sed -i 's/<a class=\"luci-link\" href=\"https:\/\/github.com\/openwrt\/luci\" target=\"_blank\">Powered by <%= ver.luciname %> (<%= ver.luciversion %>)<\/a>/OpenWrt_2305_x64_测试版 by GXNAS build @R'"$build_date"'/' package/luci-theme-argon/ucode/template/themes/argon/footer.ut
sed -i 's|<a href="https://github.com/jerrykuku/luci-theme-argon" target="_blank">ArgonTheme <%# vPKG_VERSION %></a>|<a class="luci-link" href="https://wp.gxnas.com" target="_blank">🌐固件编译者：【GXNAS博客】</a>|' package/luci-theme-argon/ucode/template/themes/argon/footer.ut
sed -i 's|<%= ver.distversion %>|<a href="https://d.gxnas.com" target="_blank">👆点这里下载最新版本</a>|' package/luci-theme-argon/ucode/template/themes/argon/footer.ut
echo "修改后的package/luci-theme-argon/ucode/template/themes/argon/footer.ut的内容是："
cat package/luci-theme-argon/ucode/template/themes/argon/footer.ut
echo "修改后的package/luci-theme-argon/ucode/template/themes/argon/footer.ut内容显示完毕！"
echo "修改前的package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut的内容是："
cat package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
echo "修改前的package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut内容显示完毕！"
sed -i "/<a class=\"luci-link\"/d; /<a href=\"https:\/\/github.com\/jerrykuku\/luci-theme-argon\"/d; s|<%= ver.distversion %>|OpenWrt_2305_x64_测试版 by GXNAS build @R$build_date|" package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
echo "修改后的package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut的内容是："
cat package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
echo "修改后的package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut内容显示完毕！"

# 修改欢迎banner
cp -f $GITHUB_WORKSPACE/personal/banner package/base-files/files/etc/banner

# 修改makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/luci\.mk/include \$(TOPDIR)\/feeds\/luci\/luci\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/lang\/golang\/golang\-package\.mk/include \$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang\-package\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHREPO/PKG_SOURCE_URL:=https:\/\/github\.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload\.github\.com/g' {}

./scripts/feeds update -a
./scripts/feeds install -a

# =========================
# 修复 sing-box 编译失败
# =========================

# 删除 feeds 中旧的 sing-box
rm -rf feeds/packages/net/sing-box
rm -rf feeds/kenzok8/sing-box

# 拉取最新 sing-box 源码
git clone --depth=1 https://github.com/SagerNet/sing-box.git feeds/packages/net/sing-box

# 清理 build_dir 缓存，避免残留 stub.go
rm -rf build_dir/target-*/sing-box-*
rm -rf staging_dir/target-*/root-*/pkginfo/sing-box.*
rm -rf tmp/info/.packageinfo-*sing-box*

# 移除已废弃的 with_ech 和 with_reality_server 编译标签
sed -i 's/with_ech,//g; s/,with_ech//g; s/with_ech//g' feeds/packages/net/sing-box/Makefile
sed -i 's/with_reality_server,//g; s/,with_reality_server//g; s/with_reality_server//g' feeds/packages/net/sing-box/Makefile

echo "========================="
echo " DIY2 配置完成……"
