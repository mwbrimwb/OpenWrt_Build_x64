#!/bin/bash
#===============================================
# Description: 2305_x64_all DIY script part 2
# File name: 2305_x64_all_diy-part2.sh
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

# 修改主机名字，修改你喜欢的就行（不能纯数字或者使用中文）
sed -i "/uci commit system/i\uci set system.@system[0].hostname='OpenWrt-HNMWB'" package/lean/default-settings/files/zzz-default-settings
sed -i "s/hostname='.*'/hostname='OpenWrt-HNMWB'/g" ./package/base-files/files/bin/config_generate

# 修改默认IP
sed -i 's/10.10.1.222/10.10.18.1/g' package/base-files/files/bin/config_generate
sed -i 's/10.10.1.222/10.10.18.1/g' package/base-files/luci2/bin/config_generate

# 设置密码为空（安装固件时无需密码登陆，然后自己修改想要的密码）
sed -i '/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./d' package/lean/default-settings/files/zzz-default-settings

# 调整 x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 设置ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# 默认 shell 为 bash
sed -i 's/\/bin\/ash/\/bin\/bash/g' package/base-files/files/etc/passwd

# samba解除root限制
sed -i 's/invalid users = root/#&/g' feeds/packages/net/samba4/files/smb.conf.template

# coremark跑分定时清除
sed -i '/\* \* \* \/etc\/coremark.sh/d' feeds/packages/utils/coremark/*

# 修改 argon 为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/Bootstrap theme/Argon theme/g' feeds/luci/collections/*/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/*/Makefile

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 替换curl修改版（无nghttp3、ngtcp2）
curl_ver=$(grep -i "PKG_VERSION:=" feeds/packages/net/curl/Makefile | awk -F'=' '{print $2}')
if [ "$curl_ver" != "8.9.1" ]; then
    echo "当前 curl 版本是: $curl_ver,开始替换......"
    rm -rf feeds/packages/net/curl
    cp -rf $GITHUB_WORKSPACE/personal/curl feeds/packages/net/curl
fi

# 报错修复
rm -rf feeds/packages/utils/v2dat
rm -rf package/feeds/packages/adguardhome
rm -rf feeds/luci/applications/luci-app-turboacc
merge_package master https://github.com/xiangfeidexiaohuo/extra-ipk package/custom luci-app-adguardhome patch/luci-app-turboacc patch/wall-luci/lua-maxminddb patch/wall-luci/luci-app-vssr

# argon 主题
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 -b js https://github.com/lwb1978/luci-theme-kucat package/luci-theme-kucat

# 更改argon主题背景
cp -f $GITHUB_WORKSPACE/personal/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# 显示增加编译时间
sed -i 's/DISTRIB_REVISION=.*/DISTRIB_REVISION='\''R'$(TZ=Asia/Shanghai date "+%Y.%m.%d")'\''/' /path/to/zzz-default-settings
sed -i 's/LEDE/OpenWrt_2305_x64_全功能版 by GXNAS build/g' package/lean/default-settings/files/zzz-default-settings

# 修改右下角脚本版本信息
sed -i 's/<a class=\"luci-link\" href=\"https:\/\/github.com\/openwrt\/luci\" target=\"_blank\">Powered by <%= ver.luciname %> (<%= ver.luciversion %>)<\/a>/OpenWrt_2305_x64_全功能版 by GXNAS build @R'"$build_date"'/' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's|<a href="https://github.com/jerrykuku/luci-theme-argon" target="_blank">ArgonTheme <%# vPKG_VERSION %></a>|<a class="luci-link" href="https://wp.gxnas.com" target="_blank">🌐固件编译者：【GXNAS博客】</a>|' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's|<%= ver.distversion %>|<a href="https://d.gxnas.com" target="_blank">👆点这里下载最新版本</a>|' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i "/<a class=\"luci-link\"/d; /<a href=\"https:\/\/github.com\/jerrykuku\/luci-theme-argon\"/d; s|<%= ver.distversion %>|OpenWrt_2305_x64_全功能版 by GXNAS build @R$build_date|" package/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm

# 修改欢迎banner
cp -f $GITHUB_WORKSPACE/personal/banner package/base-files/files/etc/banner

# 修改makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/luci\.mk/include \$(TOPDIR)\/feeds\/luci\/luci\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/lang\/golang\/golang\-package\.mk/include \$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang\-package\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHREPO/PKG_SOURCE_URL:=https:\/\/github\.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload\.github\.com/g' {}

./scripts/feeds update -a
./scripts/feeds install -a

echo "========================="
echo " DIY2 配置完成……"
