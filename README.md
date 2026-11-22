# 闹钟（iOS 版）

SwiftUI 写的闹钟 App：可以加多个闹钟，设置时间、标签、是否每天重复，到点用本地通知响铃——App 在后台、锁屏都能响。闹钟列表存在本机，开关一拨就生效。

## 在 Mac 上装到 iPhone / iPad（约 5 分钟）

1. 打开 **Xcode**，选 File → New → Project → iOS → **App**，点 Next。
2. Product Name 填 **AlarmClock**，Interface 选 **SwiftUI**，Language 选 **Swift**，其余默认，Next 保存。
3. 点开左侧的 **ContentView.swift**，内容全选删掉，换成本仓库 `ContentView.swift` 的全部内容。
4. 数据线连上设备，Xcode 顶部把运行设备选成它。
5. 项目设置 Signing & Capabilities 里，Team 选自己的 Apple ID（免费账号就行）。
6. 点 ▶ 运行。第一次打开会请求通知权限，**一定要点允许**，不然到点不会响。

免费 Apple ID 签的 App 有效期 7 天，过期后连上 Mac 再点一次 ▶ 续上；已设好的闹钟在续签后打开一次 App 会自动重新排好。

## 说明

- 响铃走的是系统本地通知，所以静音/勿扰模式下跟系统闹钟一样可能被压低声音，重要场合建议同时留一个系统闹钟兜底。
- 「仅一次」的闹钟响过之后开关还显示开着，再打开一次 App 就会按当前时间重新排到明天同一时刻。
