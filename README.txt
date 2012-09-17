AdNetworks
==========

版本说明
========
Google Admob SDK	--	6.1.4
多盟					--	3.0.3
VPON SDK			--	3.2.5
LMMOB SDK			--	2.2
Millennial Media	--	4.6.0
友盟					--	1.2.1
Youmi				--	4.0
SmartMad			--	2.0.4
微云					--	4.0
易传媒				--	2.5.2
艾徳思奇				--	2.3.0
Wooboo				--	2.3
安沃 Adwo			--	2.5.3
MobWin 聚赢			--	1.3.1
WQ 帷千				--	2.0.4
AirAD 				--	1.3.1
Ader				--	1.0.4
Baidu				--  2.1
InMobi				--	3.5.5
飞云 AdFracta		--	3.0
架势无线 Casee		--	3.0
随踪					--  iOS AdView开放API广告平台SDK

符号冲突
========
Wooboo / Adwo: Reachability.o 冲突 (已通过修改Wooboo库的类名解决)
VPon 与 LMMOB 的 _kInternetConnection 冲突 (已通过修改VPON库的变量名解决)


一些平台对于xcode版本或者sdk版本有限制， 不满足需求请不链接该平台库
========
AirAD仅支持xcode4.2, ios4.0以上。
Admob要求xcode4.2以上。

其他说明
========
有米4.0在模拟器点击会崩溃，但真机正常。

AppStore上传应用问题
========
有开发者反应上传应用时会报私有函数错误。实际是某些广告平台定义的函数名称和私有函数一致了。
SmartMad 2.0.3 的setEventDelegate
AirAD 的 setAppID (通过修改SDK的函数名已解决)
Youmi 的 setAppID (通过修改SDK的函数名已解决)
MobiSage 的 setInterval (通过修改SDK的函数名已解决)

开源库使用
========
JSONKit  		-- 友盟使用
SBJson   		-- AdView及一些平台
TouchJSON		-- AdView及一些平台
ASIHTTPRequest	-- VPON使用
SCGIFImageView	-- AdView使用