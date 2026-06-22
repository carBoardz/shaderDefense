# 实验报告：基于前向渲染的多光源 Phong 高光 Shader 实现

---

## 一、实验目的

1. 掌握 Unity 前向渲染架构的 ForwardBase 与 ForwardAdd 双 Pass 工作机制
2. 理解多光源光照叠加原理
3. 在 Shader 中正确实现 Phong 高光模型
4. 使用帧调试器观察 Pass 调用与 Draw Call 变化
5. 对比逐像素、逐顶点及 SH 光照在多光源场景下的视觉区别

---

## 二、实验原理

### 2.1 Phong 光照模型

Phong 光照模型通过三个分量计算最终光照：

```
最终颜色 = 环境光 + 漫反射 + 高光

其中：
- 环境光 = 材质颜色 × 环境光颜色
- 漫反射 = 光源颜色 × 材质颜色 × max(0, dot(法线, 光源方向))
- 高光 = 光源颜色 × 高光颜色 × pow(max(0, dot(视角方向, 反射向量)), 光泽度)
- 反射向量 = reflect(-光源方向, 法线)
```

### 2.2 前向渲染（Forward Rendering）流程

前向渲染采用双 Pass 架构：

1. **ForwardBase Pass**
   - 渲染主光源（通常是 Directional Light）
   - 处理 SH 光照（Spherical Harmonics）
   - 添加环境光
   - 每个物体渲染 1 次

2. **ForwardAdd Pass**
   - 每个附加光源（点光源、聚光灯）渲染 1 次
   - 使用 Additive Blending（混合模式：Blend One One）
   - 不写入深度缓冲（ZWrite Off）
   - 支持光照衰减与阴影

### 2.3 光源渲染模式

| 渲染模式 | 说明 | 特点 |
|---------|------|------|
| Auto | Unity 自动判断 | 通常平行光逐像素，其他光源根据情况 |
| Important | 强制逐像素 | 高质量，性能消耗大 |
| Not Important | 强制逐顶点或 SH | 低质量，性能好 |

---

## 三、实验环境

- Unity 版本：[请填写你的 Unity 版本]
- 操作系统：Windows 10/11
- 硬件配置：[请填写]

---

## 四、实验步骤

### 4.1 创建 Phong 高光 Shader

Shader 文件：`Assets/Shaders/ForwardRendering_Phong.shader`

#### 核心代码结构

```hlsl
Shader "Custom/ForwardRendering_Phong"
{
    Properties
    {
        _MainTex ("主纹理", 2D) = "white" {}
        _Specular ("高光颜色", Color) = (1, 1, 1, 1)
        _Gloss ("光泽度", Range(8, 256)) = 64
    }
    SubShader
    {
        // ForwardBase Pass
        Pass { Tags { "LightMode"="ForwardBase" } ... }
        
        // ForwardAdd Pass
        Pass { Tags { "LightMode"="ForwardAdd" } Blend One One ZWrite Off ... }
        
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
```

#### ForwardBase Pass 关键代码（Phong 高光计算）

```hlsl
// 计算反射向量
fixed3 reflectDir = reflect(-worldLightDir, worldNormal);

// Phong 高光
fixed3 specular = _LightColor0.rgb * _Specular.rgb * 
                  pow(max(0, dot(viewDir, reflectDir)), _Gloss);
```

#### ForwardAdd Pass 关键代码（附加光源叠加）

```hlsl
// 混合模式：Blend One One，实现光源叠加
Blend One One
ZWrite Off  // 不写深度，避免遮挡主光源

// 根据光源类型计算光源方向
#if defined (POINT) || defined (SPOT)
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
#else
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
#endif
```

### 4.2 创建测试场景

1. 创建球体和地面，应用 Phong 材质
2. 设置 1 个 Directional Light + 3 个附加光源（点光源/聚光灯）
3. 配置 LightController 脚本控制光源

### 4.3 光源配置

| 光源名称 | 类型 | 颜色 | Render Mode |
|---------|------|------|------------|
| Directional Light | 平行光 | 白色 | Important |
| PointLight_Red | 点光源 | 红色 | Important |
| SpotLight_Blue | 聚光灯 | 蓝色 | Important |
| PointLight_Green | 点光源 | 绿色 | Important |

---

## 五、实验数据与结果

### 5.1 Draw Call 与 Pass 统计

使用 Unity 帧调试器（Frame Debugger）测量：

| 测试场景 | 光源配置 | Draw Call | ForwardBase | ForwardAdd |
|---------|---------|-----------|-------------|------------|
| 1 | 仅主光源 | [请填写] | [请填写] | [请填写] |
| 2 | 主光源 + 1个点光源 | [请填写] | [请填写] | [请填写] |
| 3 | 主光源 + 2个点光源 | [请填写] | [请填写] | [请填写] |
| 4 | 主光源 + 3个点光源 | [请填写] | [请填写] | [请填写] |

### 5.2 渲染模式对比

| 渲染模式 | 视觉质量 | 性能（估算） | 主要特点 |
|---------|---------|------------|---------|
| Important（逐像素） | [请填写] | [请填写] | [请填写] |
| Auto（自动） | [请填写] | [请填写] | [请填写] |
| Not Important（逐顶点/SH） | [请填写] | [请填写] | [请填写] |

### 5.3 实验截图（可粘贴到此处）

[在此粘贴实验截图]

---

## 六、实验分析

### 6.1 ForwardBase 与 ForwardAdd 的区别

- **ForwardBase**：每个物体只渲染 1 次，处理主光源 + 环境光
- **ForwardAdd**：每个附加光源渲染 1 次，使用 Additive Blending 叠加
- **关系**：ForwardBase 是基础，ForwardAdd 在其基础上累加

### 6.2 多光源叠加原理

通过 Blend One One 混合模式：
```hlsl
最终颜色 = 源颜色 + 目标颜色
```

每个附加光源的颜色与主光源颜色相加，实现多光源叠加效果。

### 6.3 逐像素 vs 逐顶点 vs SH 光照对比

| 类型 | 计算位置 | 视觉质量 | 性能消耗 | 适用场景 |
|-----|---------|---------|---------|---------|
| 逐像素 | 片元着色器 | 高 | 大 | 重要物体、近景 |
| 逐顶点 | 顶点着色器 | 中 | 中 | 次要物体、远景 |
| SH 光照 | 球谐函数 | 低 | 极小 | 烘焙光源、环境光 |

---

## 七、实验结论

1. **前向渲染双 Pass 机制**：ForwardBase 处理主光源，ForwardAdd 叠加附加光源，实现多光源渲染
2. **Phong 高光模型**：通过反射向量实现真实的高光效果，光泽度参数控制高光范围与锐利度
3. **性能与质量权衡**：逐像素光照质量好但性能差，逐顶点/SH 光照相反，需根据场景合理配置
4. **Draw Call 增长**：每增加一个 Important 点光源，Draw Call 增加 1 倍，需注意性能优化

---

## 八、实验心得与体会

[在此填写你的实验心得]

---

## 九、参考文献

1. Unity 官方文档 - Lighting
2. 《Real-Time Rendering》- Tomas Akenine-Möller 等
3. Phong 光照模型原始论文（1973）
