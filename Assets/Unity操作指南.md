# Unity 前向渲染 Phong 高光实验 - 详细操作指南

## 实验目标

使用前向渲染架构制作支持多光源的 Phong 高光 Shader，通过 ForwardBase 处理主光源、ForwardAdd 叠加附加光源。对比逐顶点光照、逐像素光照、SH 光照的渲染效果。

---

## 第一步：创建材质并应用 Shader

### 1.1 创建材质

1. 在 Unity 项目窗口中，右键点击 `Assets` 文件夹
2. 选择 `Create` → `Material`
3. 将材质命名为 `Phong_Material`

### 1.2 应用 Shader

1. 选中刚创建的 `Phong_Material`
2. 在 Inspector 窗口中，点击 `Shader` 下拉框
3. 选择 `Custom` → `ForwardRendering_Phong`

### 1.3 配置材质参数

为材质添加一张纹理：
1. 准备一张图片（如砖墙、木材等）
2. 将图片拖入 Unity 项目窗口
3. 选中 `Phong_Material`，将图片拖到 `Main Texture` 槽位
4. 调整 `Specular` 颜色（建议白色）和 `Gloss` 值（建议 64-128）

---

## 第二步：创建测试场景

### 2.1 创建测试物体

1. 在菜单栏选择 `GameObject` → `3D Object` → `Sphere`
2. 将 Sphere 重命名为 `TestSphere`
3. 将 `Phong_Material` 拖到 Sphere 上

### 2.2 创建地面

1. 创建 `Cube`，缩放为 (10, 0.2, 10)，作为地面
2. 将 `Phong_Material` 拖到 Cube 上
3. 将 Cube 位置设为 (0, -0.9, 0)

### 2.3 调整视角

1. 选中 Main Camera
2. 位置设为 (0, 2, -5)
3. Rotation 设为 (15, 0, 0)

---

## 第三步：设置多光源场景

### 3.1 设置主光源（Directional Light）

1. Unity 默认有一个 Directional Light
2. 选中 Directional Light，在 Inspector 中：
   - 将 `Render Mode` 设为 `Important`（重要光源，逐像素渲染）
   - 确保 `Shadow Type` 为 `Soft Shadows`
   - 颜色设为白色，Intensity 设为 1

### 3.2 创建附加光源

#### 点光源（Point Light）

1. `GameObject` → `Light` → `Point Light`
2. 位置设为 (3, 2, 0)
3. 在 Inspector 中：
   - `Render Mode` = `Important`
   - `Color` = 红色
   - `Intensity` = 1
   - `Range` = 10
   - 名称改为 `PointLight_Red`

#### 聚光灯（Spot Light）

1. `GameObject` → `Light` → `Spot Light`
2. 位置设为 (-3, 3, 0)
3. 在 Inspector 中：
   - `Render Mode` = `Important`
   - `Color` = 蓝色
   - `Intensity` = 1
   - `Spot Angle` = 45
   - `Range` = 10
   - 名称改为 `SpotLight_Blue`

#### 再创建一个点光源

1. 创建另一个 Point Light
2. 位置设为 (0, 3, 3)
3. `Color` = 绿色
4. `Intensity` = 0.8
5. `Range` = 8
6. 名称改为 `PointLight_Green`

---

## 第四步：创建光源控制脚本

### 4.1 创建脚本

1. 在 `Assets/Scripts` 文件夹（如果没有则创建）
2. 右键 → `Create` → `C# Script`
3. 命名为 `LightController`

### 4.2 编辑脚本

双击脚本，用以下代码替换：

```csharp
using UnityEngine;
using System.Collections.Generic;

public class LightController : MonoBehaviour
{
    [Header("所有光源列表")]
    public Light[] allLights;
    
    [Header("GUI 位置")]
    public int guiX = 10;
    public int guiY = 10;
    
    private Dictionary<string, bool> lightStates = new Dictionary<string, bool>();
    private LightRenderMode currentRenderMode = LightRenderMode.Auto;
    
    void Start()
    {
        // 初始化所有光源状态
        foreach (Light light in allLights)
        {
            if (light != null)
            {
                lightStates[light.name] = light.enabled;
            }
        }
    }
    
    void Update()
    {
        // 切换光源开关
        if (Input.GetKeyDown(KeyCode.Alpha1)) ToggleLight(0);
        if (Input.GetKeyDown(KeyCode.Alpha2)) ToggleLight(1);
        if (Input.GetKeyDown(KeyCode.Alpha3)) ToggleLight(2);
        if (Input.GetKeyDown(KeyCode.Alpha4)) ToggleLight(3);
        
        // 切换渲染模式
        if (Input.GetKeyDown(KeyCode.R))
        {
            SwitchRenderMode();
        }
        
        // 重置所有光源
        if (Input.GetKeyDown(KeyCode.Space))
        {
            ResetAllLights();
        }
    }
    
    void ToggleLight(int index)
    {
        if (index < 0 || index >= allLights.Length) return;
        if (allLights[index] == null) return;
        
        allLights[index].enabled = !allLights[index].enabled;
        lightStates[allLights[index].name] = allLights[index].enabled;
        
        Debug.Log($"光源 {allLights[index].name} 已{(allLights[index].enabled ? "开启" : "关闭")}");
    }
    
    void SwitchRenderMode()
    {
        // 在 Auto、Important、Not Important 之间循环
        currentRenderMode = (LightRenderMode)(((int)currentRenderMode + 1) % 3);
        
        foreach (Light light in allLights)
        {
            if (light != null)
            {
                light.renderMode = currentRenderMode;
            }
        }
        
        Debug.Log($"所有光源渲染模式已切换为: {currentRenderMode}");
    }
    
    void ResetAllLights()
    {
        foreach (Light light in allLights)
        {
            if (light != null)
            {
                light.enabled = true;
                lightStates[light.name] = true;
            }
        }
        Debug.Log("所有光源已重置为开启状态");
    }
    
    void OnGUI()
    {
        GUI.Box(new Rect(guiX, guiY, 300, 150), "光源控制面板");
        
        GUILayout.BeginArea(new Rect(guiX + 10, guiY + 25, 280, 130));
        GUILayout.Label($"当前渲染模式: {currentRenderMode}");
        GUILayout.Space(5);
        
        // 显示每个光源的状态
        for (int i = 0; i < allLights.Length; i++)
        {
            if (allLights[i] != null)
            {
                bool isOn = GUI.Toggle(
                    new Rect(0, 25 + i * 25, 100, 20),
                    allLights[i].enabled,
                    $"[{i + 1}]"
                );
                
                GUI.Label(
                    new Rect(100, 25 + i * 25, 180, 20),
                    $"{allLights[i].name} ({allLights[i].type})"
                );
                
                if (isOn != allLights[i].enabled)
                {
                    allLights[i].enabled = isOn;
                }
            }
        }
        
        GUILayout.Space(5);
        GUILayout.Label("按 [1-4] 切换光源开关");
        GUILayout.Label("按 [R] 切换渲染模式");
        GUILayout.Label("按 [Space] 重置所有光源");
        
        GUILayout.EndArea();
    }
}
```

### 4.3 配置脚本

1. 将 `LightController.cs` 拖到 Main Camera 上
2. 选中 Main Camera，在 Inspector 中：
   - 将场景中的 4 个光源（Directional Light + 3 个附加光源）拖到 `All Lights` 数组中
   - 顺序：Directional Light, PointLight_Red, SpotLight_Blue, PointLight_Green

---

## 第五步：使用帧调试器分析 Draw Call 和 Pass

### 5.1 打开帧调试器

1. 菜单栏选择 `Window` → `Analysis` → `Frame Debugger`
2. 点击 `Enable` 按钮

### 5.2 观察实验结果

#### 测试 1：只有主光源

1. 按键盘 `2`、`3`、`4`，关闭所有附加光源
2. 只保留 Directional Light
3. 在帧调试器中观察：
   - 记录 `Draw Call` 数量
   - 展开 Draw Call，查看调用的 Pass
   - 应该只有 ForwardBase Pass

#### 测试 2：开启 1 个附加光源

1. 按键盘 `2`，开启红色点光源
2. 在帧调试器中观察：
   - Draw Call 数量是否增加
   - 是否出现了 ForwardAdd Pass

#### 测试 3：开启所有光源

1. 按空格键重置所有光源
2. 在帧调试器中观察：
   - Draw Call 总数
   - ForwardBase + ForwardAdd Pass 调用次数

#### 测试 4：切换渲染模式

1. 按 `R` 键切换渲染模式为 `Not Important`
2. 在帧调试器中观察：
   - Draw Call 数量变化
   - Pass 调用次数变化
3. 再按 `R` 切换为 `Important`，观察变化

---

## 第六步：对比不同光照类型

### 6.1 逐像素光照（Per-Pixel）

当前 Shader 默认就是逐像素光照：
- 特点：高质量、真实的高光反射
- 操作：确保光源 `Render Mode` = `Important`

### 6.2 逐顶点光照（Per-Vertex）

需要修改 Shader 中的计算方式：
1. 复制 `ForwardRendering_Phong.shader`，重命名为 `ForwardRendering_VertexLit.shader`
2. 修改 frag 函数中的光照计算为逐顶点方式（使用 UnityCG.cginc 中的 Shade4Lights 函数）

### 6.3 SH 光照（Spherical Harmonics）

Unity 的 SH 光源通过以下方式生效：
- 光源 `Render Mode` = `Auto`
- 且光源 `Baking` = `Baked` 或 `Mixed`
- SH 光源在 ForwardBase Pass 中通过 `UNITY_LIGHTMODEL_AMBIENT` 处理

---

## 第七步：记录实验数据

创建实验记录表：

| 测试场景 | 光源配置 | Draw Call 数 | ForwardBase | ForwardAdd |
|---------|---------|--------------|------------|------------|
| 1 | 仅主光源 | ? | ? | ? |
| 2 | 主光源 + 1个点光源 | ? | ? | ? |
| 3 | 主光源 + 2个点光源 | ? | ? | ? |
| 4 | 主光源 + 3个点光源 | ? | ? | ? |
| 5 | Not Important 模式 | ? | ? | ? |

---

## 常见问题排查

### 问题 1：Shader 显示为粉色
- 原因：Shader 编译错误
- 解决：检查代码语法，或删除 Shader 重新创建

### 问题 2：看不到高光
- 原因：Gloss 值过低或 Specular 颜色过暗
- 解决：增大 Gloss 值（64-256），Specular 设为白色

### 问题 3：阴影不显示
- 原因：光源未开启阴影
- 解决：在光源 Inspector 中设置 `Shadow Type` = `Soft Shadows`

### 问题 4：ForwardAdd Pass 没出现
- 原因：附加光源未开启
- 解决：确保附加光源的 `Render Mode` = `Important`

---

## 进阶实验

### 实验 A：改变光源颜色和强度
1. 调整各光源的 `Color` 和 `Intensity`
2. 观察不同颜色光源叠加后的效果

### 实验 B：调整 Gloss 值
1. 在材质 Inspector 中调整 Gloss
2. 观察高光大小和锐利程度的变化

### 实验 C：添加更多光源
1. 创建更多点光源和聚光灯
2. 观察 Draw Call 的变化趋势
3. 理解多光源对性能的影响

---

## 理论补充

### Phong 光照模型公式

```
finalColor = ambient + diffuse + specular

其中：
- ambient = materialColor * ambientLight
- diffuse = lightColor * materialColor * max(0, N·L)
- specular = lightColor * specularColor * pow(max(0, V·R), gloss)
- R = reflect(-L, N)
```

### Forward Rendering 流程

1. **ForwardBase Pass**：渲染主光源（最强或标记为 Important 的光源）+ SH 光源 + 环境光
2. **ForwardAdd Pass**：每个 Additional 光源渲染一次，使用 Additive Blending 叠加

### Render Mode 的区别

- **Auto**：Unity 自动判断，平行光通常逐像素，其他光源根据质量和设置决定
- **Important**：强制逐像素渲染
- **Not Important**：强制逐顶点或 SH 光源（节省性能）

---

## 完成检查清单

- [ ] 创建了 Phong_Material 并应用了 Shader
- [ ] 创建了测试场景（Sphere + 地面）
- [ ] 设置了多光源场景（1个平行光 + 3个附加光源）
- [ ] 配置了 LightController 脚本
- [ ] 使用帧调试器观察了 Draw Call 和 Pass
- [ ] 测试了不同光源数量下的渲染
- [ ] 记录了实验数据
- [ ] 理解了 ForwardBase 和 ForwardAdd 的区别
