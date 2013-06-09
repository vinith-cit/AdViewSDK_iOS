AdNetworks版本说明
========
名称                  -- udid     --  版本
随踪                  -- N        --  iOS AdView开放API广告平台SDK
Aduu                  -- N        --  iOS AdView开放API广告平台SDK

WQ 帷千               -- N        --    3.0.1
InMobi               -- N         --    3.7.0

艾徳思奇              -- N        --    5.2.0
安沃 Adwo            -- N        --    3.1

Baidu                -- N        --  3.2
有米 Youmi           -- N        --    4.7
多盟                 -- N        --    3.1.1
Ader                 -- N        --    1.1.0
友盟                 -- N        --    1.3.2

Google Admob SDK     -- N        --    6.4
Millennial Media     -- N        --    5.0.0
GreyStripe           --          --    4.2.1

SmartMad             -- N       --    3.0.1
架势无线 Casee        -- N        --    4.2
易传媒                -- N       --    2.6.2
飞云 AdFracta        -- N        --    4.0

VPON                --          --    3.2.9

MobWin 聚赢          --         --    1.3.2
LMMOB SDK            --          --    2.4
Yunyun 云云          --          --  3.0

米迪 Miidi          -- N         --  1.3.3

Wooboo              --           --    2.3.1
微云                --          --    4.0
AirAD               --           --    1.3.1  (1.3.2有Bug，未聚合)

说明：
1. 米迪目前只能做为自定义广告平台使用。
2. 如果要使用开放API SDK播放InMobi广告，可将InMobi目录下的代码和库文件清除，解压adpater目录下的*_OpenAPI.zip文件加入到项目。
3. 如果要使用开放API SDK播放惟千广告，如2。
4. udid项为N的是确认过为不使用udid的sdk，其他待确认。

符号冲突
========
None

版本限制
========
一些平台对于xcode版本或者SDK版本有限制， 不满足条件请不要链接该平台库。

使用说明
========
说明：
1. 有4套指令，其中armv7, armv7s, i386基于xcode4.5, iOS6.0编译； armv6基于xcode3.2.5, iOS4.2编译。
2. 目前多数平台支持armv7指令，但仍有少数平台不支持。如果要使用不支持的平台，可以将项目设为只编译armv7指令。

步骤：
1. 加入AdViewSDK和AdViewToolLevel到项目。
2. 在以前的框架基础上需要新加入AdSupport.framework,和StoreKit.framework, PassKit.framework设为可选，AdMob和安沃需要。
3. 需要新加Social.framework，设为可选，多盟需要。
4. 需要新加Twitter.framework、AdressBookUI.framework, 设为可选, GreyStripe需要。

AppStore上传应用问题
========
有开发者反应上传应用时会报私有函数错误。实际是某些广告平台定义的函数名称和私有函数一致了。
如果有，请将AdNetworks下该广告平台目录全删除，或者等待广告平台出新版。

开源库使用
========
JSONKit           -- 友盟使用
SBJson            -- 飞云使用
TouchJSON         -- AdView及Baidu,飞云使用
Reachability      -- 飞云和艾德思奇使用
SCGIFImageView    -- AdView使用(重命名)

其他说明
========
None