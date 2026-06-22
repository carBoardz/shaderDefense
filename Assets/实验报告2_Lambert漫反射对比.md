# 实验报告：逐顶点 vs 逐像素 Lambert 漫反射 Shader 实现与对比

---

## 一、实验目的

1. 编写逐顶点 Lambert 漫反射 Shader
2. 编写逐像素 Lambert 漫反射 Shader
3. 对比两种光照计算方式的视觉差异
4. 理解顶点插值对光照质量的影响
5. 分析两种方式的性能与质量权衡

---

## 二、实验原理

### 2.1 Lambert 漫反射模型

Lambert 漫反射是最基本的光照模型，公式：

```
最终颜色 = 环境光 + 漫反射

其中：
- 漫反射 = 光源颜色 × 材质颜色 × max(0, dot(法线, 光源方向))
- max(0, ...) 确保背面不被照亮
```

### 2.2 逐顶点光照（Vertex-Lit）

**流程：**
```
顶点着色器 → 计算光照 → 插值 → 片元着色器 → 输出
```

**特点：**
- 在顶点着色器中计算光照
- 光照结果在三角形面内插值
- 低多边形模型上有明显"棱角"
- 计算量小，性能好

### 2.3 逐像素光照（Pixel-Lit / Per-Pixel）

**流程：**
```
顶点着色器 → 传递法线和坐标 → 插值 → 片元着色器 → 计算光照 → 输出
```

**特点：**
- 在片元着色器中计算光照
- 每个像素独立计算
- 光照过渡平滑、真实
- 计算量大，性能消耗大

### 2.4 插值误差分析

在低多边形模型上，逐顶点光照在三角形边缘产生明显的"马赫带"（Mach band）效应，这是由于线性插值无法正确表示光照的非线性变化导致的。

---

## 三、实验环境

- Unity 版本：[请填写你的 Unity 版本]
- 操作系统：Windows 10/11
- 硬件配置：[请填写]

---

## 四、实验步骤

### 4.1 创建逐顶点 Lambert Shader

Shader 文件：`Assets/Shaders/Lambert_VertexLit.shader`

#### 顶点着色器关键代码

```hlsl
v2f vert (appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    
    // ===== 逐顶点计算光照 =====
    float3 worldNormal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
    float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
    fixed diffuse = max(0, dot(worldNormal, worldLightDir));
    
    fixed3 lightColor = _LightColor0.rgb * _Diffuse.rgb * diffuse;
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _Diffuse.rgb;
    
    o.color = fixed4(ambient + lightColor, 1.0);
    
    return o;
}
```

#### 片元着色器关键代码

```hlsl
fixed4 frag (v2f i) : SV_Target
{
    // 片元着色器只需采样纹理并与顶点计算的颜色相乘
    fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
    return fixed4(i.color.rgb * albedo, 1.0);
}
```

### 4.2 创建逐像素 Lambert Shader

Shader 文件：`Assets/Shaders/Lambert_PixelLit.shader`

#### 顶点着色器关键代码（仅传递）

```hlsl
v2f vert (appdata v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    
    // 顶点着色器仅做坐标与法线传递
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
    
    return o;
}
```

#### 片元着色器关键代码（计算光照）

```hlsl
fixed4 frag (v2f i) : SV_Target
{
    fixed3 albedo = tex2D(_MainTex, i.uv).rgb;
    
    // ===== 逐像素计算光照 =====
    fixed3 worldNormal = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
    fixed diffuse = max(0, dot(worldNormal, worldLightDir));
    
    fixed3 lightColor = _LightColor0.rgb * _Diffuse.rgb * diffuse * albedo;
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _Diffuse.rgb * albedo;
    
    return fixed4(ambient + lightColor, 1.0);
}
```

### 4.3 创建对比场景

1. 创建两个球体：
   - 左侧球体（-2, 0, 0）→ 应用逐顶点材质
   - 右侧球体（2, 0, 0）→ 应用逐像素材质
2. 配置 LambertCompareController 脚本控制实验

---

## 五、实验数据与结果

### 5.1 视觉对比记录

| 观察项 | 逐顶点（左） | 逐像素（右） |
|-------|-------------|-------------|
| 光照过渡平滑度 | ☐ 很平滑 ☐ 一般 ☐ 棱角明显 | ☐ 很平滑 ☐ 一般 ☐ 棱角明显 |
| 明暗交界线 | ☐ 清晰 ☐ 模糊 ☐ 有锯齿 | ☐ 清晰 ☐ 模糊 ☐ 有锯齿 |
| 整体真实感 | ☐ 差 ☐ 中 ☐ 好 | ☐ 差 ☐ 中 ☐ 好 |
| 低多边形表现 | ☐ 差 ☐ 中 ☐ 好 | ☐ 差 ☐ 中 ☐ 好 |

### 5.2 性能对比（估算）

| 指标 | 逐顶点 | 逐像素 |
|-----|--------|--------|
| 顶点着色器计算量 | [请填写] | [请填写] |
| 片元着色器计算量 | [请填写] | [请填写] |
| 总性能消耗 | [请填写] | [请填写] |

### 5.3 旋转平行光观察

1. 当平行光旋转时，明暗交界线的移动：
   - 逐顶点：[填写观察结果]
   - 逐像素：[填写观察结果]

2. 不同光照角度下的差异：
   [填写观察结果]

### 5.4 切换漫反射颜色

当切换不同颜色时：
- [填写观察结果]

### 5.5 实验截图（可粘贴）

[在此粘贴实验截图]

---

## 六、实验分析

### 6.1 视觉差异原因

逐顶点光照在低多边形模型上产生"棱角"的原因：
1. 光照在顶点计算，三角形面内仅做线性插值
2. 光照变化是非线性的（与角度余弦相关）
3. 线性插值无法准确表示非线性光照变化
4. 在明暗交界区域产生明显的"台阶"

### 6.2 计算量对比

**逐顶点：**
- 每个顶点计算 1 次光照
- 假设球体有 N 个顶点，则计算 N 次
- 片元着色器只做纹理采样

**逐像素：**
- 每个像素计算 1 次光照
- 假设屏幕分辨率为 1920×1080，可能需要计算数百万次
- 计算量大得多，但质量更好

### 6.3 适用场景建议

| 场景类型 | 推荐方式 | 原因 |
|---------|---------|------|
| 高多边形模型 | 逐像素 | 顶点多，插值误差小 |
| 低多边形模型 | 逐像素 | 插值误差明显，需逐像素 |
| 远景物体 | 逐顶点 | 距离远，误差不明显 |
| 近景重要物体 | 逐像素 | 需要高质量光照 |
| 移动平台 | 混合 | 根据距离和重要性选择 |

---

## 七、实验结论

1. **视觉质量**：逐像素光照明显优于逐顶点光照，特别是在低多边形模型上
2. **性能消耗**：逐顶点光照计算量小，适合性能受限平台
3. **插值误差**：逐顶点光照的线性插值会在明暗交界区域产生明显误差
4. **权衡策略**：实际项目中应根据物体重要性、距离和平台性能灵活选择

---

## 八、实验心得与体会

[在此填写你的实验心得]

---

## 九、参考文献

1. Unity 官方文档 - Shader Fundamentals
2. 《Real-Time Rendering》- Tomas Akenine-Möller 等
3. Lambert 光照模型原始文献（1760）
4. 球谐光照（SH Lighting）相关资料
