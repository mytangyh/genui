# AI app2.0 - AI推送

## 栏目列表接口

  

Postman样例

POST /ai/msgs/infolist HTTP/1.1  
Host: [cs.cnht.com.cn](http://cs.cnht.com.cn):9443  
Content-Type: application/x-www-form-urlencoded  
Cache-Control: no-cache  
Postman-Token: 012101e7-758b-4c48-9a27-223ae3a9d062

phone=17794531963

  

返回样例：

{  
    "r": 1,  
    "msg": "ok",  
    "data": \[  
        {  
            "appCode": "ths",  
            "cforum": \[  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": "2025-09-17 16:27:51",  
                    "curNoReadMsgId": "6bf1d098687249f88afe16da9ba035c3",  
                    "curNoReadMsgTitle": "测试测试",  
                    "desc": "",  
                    "fid": "1003",  
                    "fname": "投顾动态",  
                    "huaweiChannelId": "",  
                    "huaweiSubType": 0,  
                    "id": "5f3f83ed97942d25789aba19",  
                    "inputTime": 1597998061270,  
                    "miChannelId": "101833",  
                    "miSubType": 0,  
                    "msgCreateTime": "2025-09-17 16:27:51",  
                    "msgid": "6bf1d098687249f88afe16da9ba035c3",  
                    "msgtime": 1758097671797,  
                    "msgtitle": "测试测试",  
                    "newmsg": "测试测试",  
                    "number": 1,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV6yOEG9A0AAAAAHiC\_d0578.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV6yOEG9A0AAAAAHiC_d0578.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1730985911802,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": "2025-09-16 15:46:50",  
                    "curNoReadMsgId": "84eca29ac723484cbda7a74d4d3470b5",  
                    "curNoReadMsgTitle": "test002",  
                    "desc": "",  
                    "fid": "1005",  
                    "fname": "我的消息",  
                    "huaweiChannelId": "",  
                    "huaweiSubType": 0,  
                    "id": "5f3f85fc97942d25789aba1a",  
                    "inputTime": 1597998588291,  
                    "miChannelId": "",  
                    "miSubType": 0,  
                    "msgCreateTime": "2025-09-16 15:46:50",  
                    "msgid": "84eca29ac723484cbda7a74d4d3470b5",  
                    "msgtime": 1758008810270,  
                    "msgtitle": "test002",  
                    "newmsg": "test002",  
                    "number": 2,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV6y-EQGN7AAAAANSVYCU045.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV6y-EQGN7AAAAANSVYCU045.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1690956648294,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": "2025-12-09 09:10:05",  
                    "curNoReadMsgId": "a247a9cf879c4f159c5f70a49b3a8349",  
                    "curNoReadMsgTitle": "今日有1只新股可申购：元创股份",  
                    "desc": "",  
                    "fid": "1001",  
                    "fname": "新股申购",  
                    "huaweiChannelId": "",  
                    "huaweiSubType": 0,  
                    "id": "5f3f860997942d25789aba1b",  
                    "inputTime": 1597998601685,  
                    "miChannelId": "",  
                    "miSubType": 0,  
                    "msgCreateTime": "2025-12-09 09:10:05",  
                    "msgid": "a247a9cf879c4f159c5f70a49b3a8349",  
                    "msgtime": 1765242605300,  
                    "msgtitle": "今日有1只新股可申购：元创股份",  
                    "newmsg": "今日有1只新股可申购：元创股份",  
                    "number": 36,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV64mEWAiMAAAAAN3evm8920.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV64mEWAiMAAAAAN3evm8920.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1690955976725,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": "2025-12-04 18:56:48",  
                    "curNoReadMsgId": "d31290ee3e2c4e16bff315f4416070ea",  
                    "curNoReadMsgTitle": "12月3日持仓该股ETF资金净流入9104.35万元，3日累计净流出5013.28万元",  
                    "desc": "系统公告",  
                    "fid": "1002",  
                    "fname": "系统公告",  
                    "huaweiChannelId": "",  
                    "huaweiSubType": 0,  
                    "id": "5f3f861a97942d25789aba1c",  
                    "inputTime": 1597998618747,  
                    "miChannelId": "",  
                    "miSubType": 0,  
                    "msgCreateTime": "2025-12-04 18:56:48",  
                    "msgid": "d31290ee3e2c4e16bff315f4416070ea",  
                    "msgtime": 1764845808796,  
                    "msgtitle": "12月3日持仓该股ETF资金净流入9104.35万元，3日累计净流出5013.28万元",  
                    "newmsg": "12月3日持仓该股ETF资金净流入9104.35万元，3日累计净流出5013.28万元",  
                    "number": 5,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV67GETNiXAAAAALe6nIc424.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV67GETNiXAAAAALe6nIc424.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1703142610352,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": null,  
                    "curNoReadMsgId": null,  
                    "curNoReadMsgTitle": null,  
                    "desc": "智能盯盘",  
                    "fid": "1006",  
                    "fname": "智能盯盘",  
                    "huaweiChannelId": null,  
                    "huaweiSubType": 0,  
                    "id": "600816b097942d299c541cd5",  
                    "inputTime": 1611142832219,  
                    "miChannelId": null,  
                    "miSubType": 0,  
                    "msgCreateTime": null,  
                    "msgid": null,  
                    "msgtime": 0,  
                    "msgtitle": null,  
                    "newmsg": null,  
                    "number": 0,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV7ZuEd5nrAAAAAMOqvaE028.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV7ZuEd5nrAAAAAMOqvaE028.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1628827439523,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": null,  
                    "curNoReadMsgId": null,  
                    "curNoReadMsgTitle": null,  
                    "desc": "策略推送",  
                    "fid": "1010",  
                    "fname": "策略宝",  
                    "huaweiChannelId": null,  
                    "huaweiSubType": 0,  
                    "id": "6088d01197942d7c0f724a5b",  
                    "inputTime": 1619578897766,  
                    "miChannelId": null,  
                    "miSubType": 0,  
                    "msgCreateTime": null,  
                    "msgid": null,  
                    "msgtime": 0,  
                    "msgtitle": null,  
                    "newmsg": null,  
                    "number": 0,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV7d-EEaJ6AAAAAMiyYWY171.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV7d-EEaJ6AAAAAMiyYWY171.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1628827507905,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": null,  
                    "curNoReadMsgId": null,  
                    "curNoReadMsgTitle": null,  
                    "desc": "新闻资讯",  
                    "fid": "1009",  
                    "fname": "新闻资讯",  
                    "huaweiChannelId": null,  
                    "huaweiSubType": 0,  
                    "id": "60e7ead997942d5ba45aa990",  
                    "inputTime": 1625811673623,  
                    "miChannelId": null,  
                    "miSubType": 0,  
                    "msgCreateTime": null,  
                    "msgid": null,  
                    "msgtime": 0,  
                    "msgtitle": null,  
                    "newmsg": null,  
                    "number": 0,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV7TGEUNIQAAAAAJJRnpE185.png](https://cs.cnht.com.cn:9443/group1/M00/00/30/xhwAU2EV7TGEUNIQAAAAAJJRnpE185.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1628827333760,  
                    "vivoSubType": 0  
                },  
                {  
                    "appCode": "ths",  
                    "curNoReadMsgCreateTime": null,  
                    "curNoReadMsgId": null,  
                    "curNoReadMsgTitle": null,  
                    "desc": "积分商城提醒",  
                    "fid": "1011",  
                    "fname": "积分商城",  
                    "huaweiChannelId": "",  
                    "huaweiSubType": 0,  
                    "id": "61c1c54f97942d2f733649b7",  
                    "inputTime": 1640088911487,  
                    "miChannelId": "",  
                    "miSubType": 0,  
                    "msgCreateTime": null,  
                    "msgid": null,  
                    "msgtime": 0,  
                    "msgtitle": null,  
                    "newmsg": null,  
                    "number": 0,  
                    "oppoSubType": 0,  
                    "path": "[https://cs.cnht.com.cn:9443/group1/M00/00/35/xhwAU2IDlWOEOlzTAAAAACbong0906.png](https://cs.cnht.com.cn:9443/group1/M00/00/35/xhwAU2IDlWOEOlzTAAAAACbong0906.png)",  
                    "pid": "5f3f83d897942d25789aba18",  
                    "subType": 0,  
                    "updateTime": 1690955993424,  
                    "vivoSubType": 0  
                }  
            \],  
            "fid": "1000",  
            "fname": "消息中心",  
            "id": "5f3f83d897942d25789aba18",  
            "inputTime": 1597998040455,  
            "number": 44,  
            "path": "",  
            "updateTime": 0,  
            "huaweiSubType": 0,  
            "huaweiChannelId": null,  
            "miSubType": 0,  
            "miChannelId": null,  
            "oppoSubType": 0,  
            "subType": 0,  
            "vivoSubType": 0,  
            "desc": null  
        }  
    \]  
}

## 消息列表接口

  

~POST /ai/msgs/unread HTTP/1.1~

[https://cs.cnht.com.cn:9443/ai/msgs/msgList](https://cs.cnht.com.cn:9443/ai/msgs/msgList)

  
Host: [cs.cnht.com.cn](http://cs.cnht.com.cn):9443  
Content-Type: application/x-www-form-urlencoded  
Cache-Control: no-cache  
Postman-Token: c3c39f80-2ad5-4c2a-a364-fb7eaaf86b38

phone=18257137196&read=0 或者 -1    0 表示未读，-1 表示全部消息

  

返回样例：

{  
    "r": 1,  
    "msg": "ok",  
    "data": \[  
        {  
            "appcode": "ths",  
            "author": "ths",  
            "collect": 0,  
            "content": "&lt;p&gt;江天科技开启申购，申购代码为920121，申购价格为21.2100元，当日账户申购上限为59.4600万股。&lt;/p&gt;",  
            "createtime": 1765847404911,  
            "cv": "pt",  
            "express": null,  
            "ext": null,  
            "forum": "1001",  
            "intro": "今日有1只新股可申购：江天科技",  
            "msgid": "0f2d2ad4365843f791b38aed0a5ddefa",  
            "pushType": 2,  
            "read": 0,  
            "source": "ths",  
            "title": "今日有1只新股可申购：江天科技"  
        },  
        {  
            "appcode": "ths",  
            "author": "ths",  
            "collect": 0,  
            "content": "&lt;p&gt;今日有1只新债可申购：鼎捷转债，申购代码123263，转股价格43.540元。&lt;/p&gt;",  
            "createtime": 1765762205796,  
            "cv": "pt",  
            "express": null,  
            "ext": null,  
            "forum": "1001",  
            "intro": "今日有1只新债可申购：鼎捷转债。",  
            "msgid": "3eb28a34b0504b5a8e0204fcb64acbb4",  
            "pushType": 2,  
            "read": 0,  
            "source": "ths",  
            "title": "今日有1只新债可申购：鼎捷转债。"  
        }  
    \],  
    "page": null  
}

  

## 执行消息已读接口

POST /ai/msgs/read HTTP/1.1  
Host: [cs.cnht.com.cn](http://cs.cnht.com.cn):9443  
Content-Type: application/x-www-form-urlencoded  
Cache-Control: no-cache  
Postman-Token: b643eaa4-abd4-4962-bab5-a2e60e590ab2

phone=18257137196&appcode=ths&msgids=6bf1d098687249f88afe16da9ba035c3%2C84eca29ac723484cbda7a74d4d3470b5

  

返回样例：

{"msg":"ok","r":1}

  

## 触发AI解读未读消息接口

POST /ai/msgs/flow/run\_by\_flux HTTP/1.1  
Host: [cs.cnht.com.cn](http://cs.cnht.com.cn):9443  
Content-Type: application/x-www-form-urlencoded  
Cache-Control: no-cache  
Postman-Token: 4b5d3b7d-3cd4-4297-a0d2-69f41a671055

phone=18257137196&forum=1001

返回值：

工作流返回

## 用户历史未读消息AI解读列表

  

POST /ai/msgs/getAgentHistory HTTP/1.1  
Host: [cs.cnht.com.cn](http://cs.cnht.com.cn):9443  
Content-Type: application/x-www-form-urlencoded  
Cache-Control: no-cache  
Postman-Token: fc9da0ec-73c5-4a15-aba1-9778d8e24e22

phone=18257137196&start=1765123200000&end=1775123200000

  

返回样例：

\[  
    {  
        "time": 1765259963535,  
        "content": "{\\"data\\":{\\"result\\":{\\"text\\":\\"好的，我将根据您提供的消息列表进行汇总解读。首先，我会将消息按类型分类，然后提取关键数据并进行解读。以下是汇总结果：\\\\n\\\\n### 1. 新股申购\\\\n#### 问题：今日有哪些新股可申购？\\\\n#### 关键数据：\\\\n- \*\*元创股份\*\*（申购代码：001325），发行价：24.75元，申购上限：1.95万股\\\\n- \*\*纳百川\*\*（申购代码：301667），发行价：22.63元，申购上限：0.65万股\\\\n- \*\*优迅股份\*\*（申购代码：787807），发行价：51.66元，申购上限：0.45万股\\\\n- \*\*昂瑞微\*\*（申购代码：787790），发行价：83.06元，申购上限：0.35万股\\\\n- \*\*沐曦股份\*\*（申购代码：787802），发行价：104.66元，申购上限：0.60万股\\\\n- \*\*百奥赛图\*\*（申购代码：78779），发行价：26.68元，申购上限：0.75万股\\\\n- \*\*摩尔线程\*\*（申购代码：787795），发行价：114.28元，申购上限：1.10万股\\\\n- \*\*中国铀业\*\*（申购代码：001280），发行价：17.89元，申购上限：5.20万股\\\\n- \*\*精创电气\*\*（申购代码：920035），发行价：12.10元，申购上限：65.07万股\\\\n- \*\*海安集团\*\*（申购代码：001233），发行价：48.00元，申购上限：1.45万股\\\\n- \*\*南特科技\*\*（申购代码：920124），发行价：8.66元，申购上限：167.32万股\\\\n- \*\*南网数字\*\*（申购代码：301638），发行价：5.69元，申购上限：4.75万股\\\\n- \*\*恒坤新材\*\*（申购代码：787727），发行价：14.99元，申购上限：1.05万股\\\\n- \*\*大鹏工业\*\*（申购代码：920091），发行价：9.00元，申购上限：67.50万股\\\\n- \*\*北矿检测\*\*（申购代码：920160），发行价：6.70元，申购上限：127.44万股\\\\n- \*\*德力佳\*\*（申购代码：732092），发行价：46.68元，申购上限：0.95万股\\\\n- \*\*中诚咨询\*\*（申购代码：920003），发行价：14.27元，申购上限：63.00万股\\\\n- \*\*丰倍生物\*\*（申购代码：732334），发行价：24.49元，申购上限：1.10万股\\\\n- \*\*大明电子\*\*（申购代码：732376），发行价：12.55元，申购上限：0.95万股\\\\n- \*\*丹娜生物\*\*（申购代码：920009），发行价：17.10元，申购上限：36.00万股\\\\n- \*\*必贝特\*\*（申购代码：787759），发行价：17.78元，申购上限：1.40万股\\\\n- \*\*西安奕材\*\*（申购代码：787783），发行价：8.62元，申购上限：5.35万股\\\\n- \*\*超颖电子\*\*（申购代码：732175），发行价：17.08元，申购上限：1.25万股\\\\n- \*\*泰凯英\*\*（申购代码：920020），发行价：7.50元，申购上限：199.12万股\\\\n- \*\*禾元生物\*\*（申购代码：787765），发行价：29.06元，申购上限：1.40万股\\\\n- \*\*马可波罗\*\*（申购代码：001386），发行价：13.75元，申购上限：3.20万股\\\\n- \*\*道生天合\*\*（申购代码：730026），发行价：5.98元，申购上限：2.75万股\\\\n\\\\n#### 解读分析：\\\\n根据现行规则，新股申购需满足市值门槛，且中签后需缴款。高发行价的新股通常对应较高的市场预期，但风险也相对较大。申购上限较高的新股意味着更多的投资者可以参与。\\\\n\\\\n#### 结论：\\\\n今日有多只新股可申购，投资者需根据自身情况选择参与。\\\\n\\\\n### 2. 新债申购\\\\n#### 问题：今日有哪些新债可申购？\\\\n#### 关键数据：\\\\n- \*\*普联转债\*\*（申购代码：123261），转股价格：18.26元\\\\n- \*\*茂莱转债\*\*（申购代码：118061），转股价格：364.43元\\\\n- \*\*瑞可转债\*\*（申购代码：118061），转股价格：73.85元\\\\n- \*\*卓镁转债\*\*（申购代码：123261），转股价格：52.30元\\\\n- \*\*颀中转债\*\*（申购代码：1805），转股价格：13.75元\\\\n- \*\*锦浪转02\*\*（申购代码：123259），转股价格：89.82元\\\\n- \*\*福能转债\*\*（申购代码：110099），转股价格：9.84元\\\\n- \*\*金25转债\*\*（申购代码：113699），转股价格：63.46元\\\\n\\\\n#### 解读分析：\\\\n新债的转股价格反映了正股的估值。高转股价格的新债通常对应正股估值较高或溢价率较低，投资者需关注正股的市场表现。\\\\n\\\\n#### 结论：\\\\n今日有多只新债可申购，投资者需根据正股的市场表现和转股价格进行选择。\\\\n\\\\n### 3. 交易灵感\\\\n#### 问题：有哪些股票的技术指标发生了变化？\\\\n#### 关键数据：\\\\n- \*\*600601\*\*（方正科技）：KDJ指标超买后下行，判断为利空\\\\n- \*\*600403\*\*（大有能源）：KDJ指标超买后回落，判断为利空\\\\n- \*\*600601\*\*（方正科技）：KDJ指标超买后下行，判断为利空\\\\n- \*\*600403\*\*（大有能源）：KDJ指标超买后下行，判断为利空\\\\n- \*\*600601\*\*（方正科技）：KDJ指标低位金叉，判断为利好\\\\n- \*\*600403\*\*（大有能源）：KDJ指标低位金叉，判断为利好\\\\n- \*\*600601\*\*（方正科技）：KDJ指标超买，判断为利空\\\\n- \*\*600403\*\*（大有能源）：KDJ指标低位金叉，判断为利好\\\\n\\\\n#### 解读分析：\\\\nKDJ指标是一种常用的技术分析工具，通过观察K、D、J三条曲线的变化来判断股票的买卖信号。KDJ金叉通常意味着市场短期趋势向好，而超买后下行则预示着股价可能回调。\\\\n\\\\n#### 结论：\\\\n多只股票的KDJ指标发生了变化，投资者需关注这些技术信号，结合其他因素进行决策。\\\\n\\\\n### 4. 行业新闻\\\\n#### 问题：有哪些行业新闻值得关注？\\\\n#### 关键数据：\\\\n- \*\*600601\*\*（方正科技）：英特尔叫停NEX部门剥离计划，判断为中性\\\\n- \*\*600601\*\*（方正科技）：FluidStack洽谈超7亿美元融资，判断为利好\\\\n\\\\n#### 解读分析：\\\\n英特尔叫停NEX部门剥离计划对方正科技的直接影响较小，但可能影响科技行业的整体氛围。FluidStack洽谈超7亿美元融资表明该企业在市场上有较强的资金吸引力和发展潜力，对方正科技可能带来积极影响。\\\\n\\\\n#### 结论：\\\\n今日有两条行业新闻，投资者需关注这些新闻对相关股票的影响。\\\\n\\\\n### 5. 证券消息\\\\n#### 问题：有哪些证券消息？\\\\n#### 关键数据：\\\\n- 证券消息推送，内容不详\\\\n\\\\n#### 解读分析：\\\\n证券消息推送内容不详，建议投资者关注具体消息内容，以获取更多信息。\\\\n\\\\n#### 结论：\\\\n今日有两条证券消息，内容不详，建议关注具体消息内容。\\\\n\\\\n以上是根据您提供的消息列表进行的汇总解读。如果您有其他问题或需要进一步的信息，请随时告知。\\",\\"reasoningContent\\":\\"\\"},\\"status\\":\\"TRUE\\",\\"cost\\":0,\\"id\\":\\"25670\_1764242773335\_endComponent\\",\\"name\\":\\"结束\\",\\"input\\":{\\"text\\":\\"好的，我将根据您提供的消息列表进行汇总解读。首先，我会将消息按类型分类，然后提取关键数据并进行解读。以下是汇总结果：\\\\n\\\\n### 1. 新股申购\\\\n#### 问题：今日有哪些新股可申购？\\\\n#### 关键数据：\\\\n- \*\*元创股份\*\*（申购代码：001325），发行价：24.75元，申购上限：1.95万股\\\\n- \*\*纳百川\*\*（申购代码：301667），发行价：22.63元，申购上限：0.65万股\\\\n- \*\*优迅股份\*\*（申购代码：787807），发行价：51.66元，申购上限：0.45万股\\\\n- \*\*昂瑞微\*\*（申购代码：787790），发行价：83.06元，申购上限：0.35万股\\\\n- \*\*沐曦股份\*\*（申购代码：787802），发行价：104.66元，申购上限：0.60万股\\\\n- \*\*百奥赛图\*\*（申购代码：78779），发行价：26.68元，申购上限：0.75万股\\\\n- \*\*摩尔线程\*\*（申购代码：787795），发行价：114.28元，申购上限：1.10万股\\\\n- \*\*中国铀业\*\*（申购代码：001280），发行价：17.89元，申购上限：5.20万股\\\\n- \*\*精创电气\*\*（申购代码：920035），发行价：12.10元，申购上限：65.07万股\\\\n- \*\*海安集团\*\*（申购代码：001233），发行价：48.00元，申购上限：1.45万股\\\\n- \*\*南特科技\*\*（申购代码：920124），发行价：8.66元，申购上限：167.32万股\\\\n- \*\*南网数字\*\*（申购代码：301638），发行价：5.69元，申购上限：4.75万股\\\\n- \*\*恒坤新材\*\*（申购代码：787727），发行价：14.99元，申购上限：1.05万股\\\\n- \*\*大鹏工业\*\*（申购代码：920091），发行价：9.00元，申购上限：67.50万股\\\\n- \*\*北矿检测\*\*（申购代码：920160），发行价：6.70元，申购上限：127.44万股\\\\n- \*\*德力佳\*\*（申购代码：732092），发行价：46.68元，申购上限：0.95万股\\\\n- \*\*中诚咨询\*\*（申购代码：920003），发行价：14.27元，申购上限：63.00万股\\\\n- \*\*丰倍生物\*\*（申购代码：732334），发行价：24.49元，申购上限：1.10万股\\\\n- \*\*大明电子\*\*（申购代码：732376），发行价：12.55元，申购上限：0.95万股\\\\n- \*\*丹娜生物\*\*（申购代码：920009），发行价：17.10元，申购上限：36.00万股\\\\n- \*\*必贝特\*\*（申购代码：787759），发行价：17.78元，申购上限：1.40万股\\\\n- \*\*西安奕材\*\*（申购代码：787783），发行价：8.62元，申购上限：5.35万股\\\\n- \*\*超颖电子\*\*（申购代码：732175），发行价：17.08元，申购上限：1.25万股\\\\n- \*\*泰凯英\*\*（申购代码：920020），发行价：7.50元，申购上限：199.12万股\\\\n- \*\*禾元生物\*\*（申购代码：787765），发行价：29.06元，申购上限：1.40万股\\\\n- \*\*马可波罗\*\*（申购代码：001386），发行价：13.75元，申购上限：3.20万股\\\\n- \*\*道生天合\*\*（申购代码：730026），发行价：5.98元，申购上限：2.75万股\\\\n\\\\n#### 解读分析：\\\\n根据现行规则，新股申购需满足市值门槛，且中签后需缴款。高发行价的新股通常对应较高的市场预期，但风险也相对较大。申购上限较高的新股意味着更多的投资者可以参与。\\\\n\\\\n#### 结论：\\\\n今日有多只新股可申购，投资者需根据自身情况选择参与。\\\\n\\\\n### 2. 新债申购\\\\n#### 问题：今日有哪些新债可申购？\\\\n#### 关键数据：\\\\n- \*\*普联转债\*\*（申购代码：123261），转股价格：18.26元\\\\n- \*\*茂莱转债\*\*（申购代码：118061），转股价格：364.43元\\\\n- \*\*瑞可转债\*\*（申购代码：118061），转股价格：73.85元\\\\n- \*\*卓镁转债\*\*（申购代码：123261），转股价格：52.30元\\\\n- \*\*颀中转债\*\*（申购代码：1805），转股价格：13.75元\\\\n- \*\*锦浪转02\*\*（申购代码：123259），转股价格：89.82元\\\\n- \*\*福能转债\*\*（申购代码：110099），转股价格：9.84元\\\\n- \*\*金25转债\*\*（申购代码：113699），转股价格：63.46元\\\\n\\\\n#### 解读分析：\\\\n新债的转股价格反映了正股的估值。高转股价格的新债通常对应正股估值较高或溢价率较低，投资者需关注正股的市场表现。\\\\n\\\\n#### 结论：\\\\n今日有多只新债可申购，投资者需根据正股的市场表现和转股价格进行选择。\\\\n\\\\n### 3. 交易灵感\\\\n#### 问题：有哪些股票的技术指标发生了变化？\\\\n#### 关键数据：\\\\n- \*\*600601\*\*（方正科技）：KDJ指标超买后下行，判断为利空\\\\n- \*\*600403\*\*（大有能源）：KDJ指标超买后回落，判断为利空\\\\n- \*\*600601\*\*（方正科技）：KDJ指标超买后下行，判断为利空\\\\n- \*\*600403\*\*（大有能源）：KDJ指标超买后下行，判断为利空\\\\n- \*\*600601\*\*（方正科技）：KDJ指标低位金叉，判断为利好\\\\n- \*\*600403\*\*（大有能源）：KDJ指标低位金叉，判断为利好\\\\n- \*\*600601\*\*（方正科技）：KDJ指标超买，判断为利空\\\\n- \*\*600403\*\*（大有能源）：KDJ指标低位金叉，判断为利好\\\\n\\\\n#### 解读分析：\\\\nKDJ指标是一种常用的技术分析工具，通过观察K、D、J三条曲线的变化来判断股票的买卖信号。KDJ金叉通常意味着市场短期趋势向好，而超买后下行则预示着股价可能回调。\\\\n\\\\n#### 结论：\\\\n多只股票的KDJ指标发生了变化，投资者需关注这些技术信号，结合其他因素进行决策。\\\\n\\\\n### 4. 行业新闻\\\\n#### 问题：有哪些行业新闻值得关注？\\\\n#### 关键数据：\\\\n- \*\*600601\*\*（方正科技）：英特尔叫停NEX部门剥离计划，判断为中性\\\\n- \*\*600601\*\*（方正科技）：FluidStack洽谈超7亿美元融资，判断为利好\\\\n\\\\n#### 解读分析：\\\\n英特尔叫停NEX部门剥离计划对方正科技的直接影响较小，但可能影响科技行业的整体氛围。FluidStack洽谈超7亿美元融资表明该企业在市场上有较强的资金吸引力和发展潜力，对方正科技可能带来积极影响。\\\\n\\\\n#### 结论：\\\\n今日有两条行业新闻，投资者需关注这些新闻对相关股票的影响。\\\\n\\\\n### 5. 证券消息\\\\n#### 问题：有哪些证券消息？\\\\n#### 关键数据：\\\\n- 证券消息推送，内容不详\\\\n\\\\n#### 解读分析：\\\\n证券消息推送内容不详，建议投资者关注具体消息内容，以获取更多信息。\\\\n\\\\n#### 结论：\\\\n今日有两条证券消息，内容不详，建议关注具体消息内容。\\\\n\\\\n以上是根据您提供的消息列表进行的汇总解读。如果您有其他问题或需要进一步的信息，请随时告知。\\",\\"reasoningContent\\":\\"\\"},\\"usage\\":{\\"completion\_tokens\\":0,\\"prompt\_tokens\\":0,\\"type\\":\\"normal\\"}},\\"type\\":\\"single\_middle\_process\_end\\",\\"cost\_time\\":0.0}"  
    }  
\]

# 补充：

## 消息详情接口

GET /message/rs/msgs/content?msgid=a247a9cf879c4f159c5f70a49b3a8349 HTTP/1.1  
Host: [cs.cnht.com.cn](http://cs.cnht.com.cn):9443  
Content-Type: application/x-www-form-urlencoded  
token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJwYXlsb2FkIjoie1wiY2xpZW50XCI6XCJnYW56aGktbXNnXCIsXCJ0aW1lb3V0XCI6ODY0MDAsXCJ1c2VySWRcIjoxODI1NzEzNzE5Nn0iLCJleHAiOjE3MDMxNDI4NDkzMTN9.n50KjQ7BCCFkTwWMDEC0tcizH6c8IZxcD1G5lih8WzY  
Cache-Control: no-cache  
Postman-Token: 4f4fb67b-15d2-4435-8c3b-06ea6be7afe9