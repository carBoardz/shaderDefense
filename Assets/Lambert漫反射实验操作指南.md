# Lambert 漫反射 Shader 实验 - 逐顶点 vs 逐像素

## 实验目标

1. 创建逐顶点 Lambert 漫反射 Shader
2. 创建逐像素 Lambert 漫反射 Shader
3. 对比两者的视觉差异
4. 调节漫反射颜色、旋转平行光，观察明暗变化

---

## 第一步：创建两个材质

### 1.1 创建逐顶点材质

1. 在 Unity 项目窗口，右键 `Assets` 文件夹
2. 选择 `Create` → `Material`
3. 命名为 `Lambert_VertexMat`
4. 在 Inspector 中，选择 `Shader` → `Custom` → `Lambert_VertexLit`

### 1.2 创建逐像素材质

1. 同样创建另一个材质
2. 命名为 `Lambert_PixelMat`
3. 在 Inspector 中，选择 `Shader` → `Custom` → `Lambert_PixelLit`

### 1.3 可选：添加纹理

为了效果更明显，建议给两个材质添加相同的纹理：
1. 找一张图片（如砖墙、大理石等）
2. 将图片拖入 Unity
3. 将图片分别拖到两个材质的 `Main Texture` 槽位

---

## 第二步：创建测试场景

### 2.1 创建球体（用于对比）

1. `GameObject` → `3D Object` → `Sphere`
2. 重命名为 `Sphere_Vertex`
3. 位置设为 `(-2, 0, 0)`
4. 将 `Lambert_VertexMat` 拖到球体上

### 2.2 创建另一个球体

1. 复制上面的球体（Ctrl+D）
2. 重命名为 `Sphere_Pixel`
3. 位置设为 `(2, 0, 0)`
4. 将 `Lambert_PixelMat` 拖到球体上

### 2.3 创建地面

1. `GameObject` → `3D Object` → `Cube`
2. 缩放为 `(10, 0.2, 10)`
3. 位置设为 `(0, -0.9, 0)`
4. 应用任意材质（也可以用上面的材质）

### 2.4 调整摄像机视角

1. 选中 Main Camera
2. 位置设为 `(0, 2, -5)`
3. Rotation 设为 `(15, 0, 0)`

---

## 第三步：配置控制器脚本

### 3.1 配置 LightController

1. 在场景中创建空 GameObject（`GameObject` → `Create Empty`）
2. 命名为 `LambertController`
3. 将 `LambertCompareController.cs` 拖到该物体上
4. 在 Inspector 中配置参数：
   - **Target Objects**：拖入两个球体
   - **Directional Light**：拖入场景中的 Directional Light
   - **Vertex Lit Material**：拖入 `Lambert_VertexMat`
   - **Pixel Lit Material**：拖入 `Lambert_PixelMat`

---

## 第四步：开始对比实验

### 操作快捷键

| 按键 | 功能 |
|------|------|
| C | 切换渲染模式 |
| ← 或 A | 向左旋转平行光 |
| → 或 D | 向右旋转平行光 |
| Q | 切换漫反射颜色 |

### 实验步骤

#### 1. 观察逐顶点 vs 逐像素的视觉差异

**左侧球体（Vertex Lit）特点：**
- 光照在顶点上计算，然后插值到片元
- 低多边形模型上会有明显的"棱角"
- 高光（虽然本实验没有）会呈现块状
- 性能较好

**右侧球体（Pixel Lit）特点：**
- 每个像素独立计算光照
- 光照过渡更平滑、自然
- 精度更高，真实感更强
- 性能消耗更大

**观察重点：**
- 两个球体亮度相同吗？
- 明暗过渡区域哪个更平滑？
- 在球体边缘，两者区别明显吗？

#### 2. 旋转平行光，观察明暗变化

1. 按住 `D` 键，让平行光持续向右旋转
2. 观察：
   - 阴影的移动
   - 明暗交界线的位置变化
   - 两个球体明暗变化的同步性

#### 3. 切换漫反射颜色

1. 按 `Q` 键，依次切换颜色
2. 观察：
   - 颜色变化是否同步
   - 不同颜色下的明暗对比差异

---

## 第五步：理论对比

### 逐顶点 Lambert 流程

```
顶点着色器 → 计算光照 → 插值 → 片元着色器 → 输出
```

**顶点着色器代码（核心部分）：**
```hlsl
// 在顶点着色器中计算光照
float3 worldNormal = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
float3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
fixed diffuse = max(0, dot(worldNormal, worldLightDir));
o.color = fixed4(UNITY_LIGHTMODEL_AMBIENT.rgb * _Diffuse.rgb + 
                 _LightColor0.rgb * _Diffuse.rgb * diffuse, 1.0);
```

### 逐像素 Lambert 流程

```
顶点着色器 → 传递法线和坐标 → 插值 → 片元着色器 → 计算光照 → 输出
```

**顶点着色器代码（仅传递）：**
```hlsl
// 顶点着色器仅做传递
o.worldNormal = UnityObjectToWorldNormal(v.normal);
o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
```

**片元着色器代码（计算光照）：**
```hlsl
// 在片元着色器中计算光照
fixed3 worldNormal = normalize(i.worldNormal);
fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
fixed diffuse = max(0, dot(worldNormal, worldLightDir));
```

---

## 第六步：进阶实验（可选）

### 实验 A：使用低多边形模型

1. 创建一个 Cube 或 Plane
2. 分别应用两种材质
3. 观察逐顶点光照的"棱角"现象更明显

### 实验 B：改变光源颜色

1. 选中 Directional Light
2. 在 Inspector 中改变 `Color` 属性
3. 观察两个球体的变化

### 实验 C：调整环境光

1. `Window` → `Rendering` → `Lighting`
2. 切换到 `Environment` 标签
3. 调整 `Ambient Intensity`
4. 观察两个球体的暗部变化

---

## 实验数据记录表

| 测试项 | 逐顶点 | 逐像素 |
|-------|--------|--------|
| 光照过渡平滑度 | ☐ 平滑 ☐ 一般 ☐ 棱角 | ☐ 平滑 ☐ 一般 ☐ 棱角 |
| 明暗交界线 | ☐ 清晰 ☐ 模糊 | ☐ 清晰 ☐ 模糊 |
| 视觉质量 | ☐ 差 ☐ 中 ☐ 好 | ☐ 差 ☐ 中 ☐ 好 |
| 性能（估算） | ☐ 快 ☐ 中 ☐ 慢 | ☐ 快 ☐ 中 ☐ 慢 |

---

## 常见问题

### 问题 1：两个球体看起来一样？
- **原因**：可能球体细分面数太多，区别不明显
- **解决**：创建 Cube（6面）或降低球体细分面数

### 问题 2：没有看到明暗变化？
- **原因**：平行光角度或强度不合适
- **解决**：在 Scene 视图中旋转 Directional Light，让光照角度更明显

### 问题 3：Shder 显示为粉色？
- **原因**：代码错误或 Shader 未正确导入
- **解决**：检查 Shader 文件代码是否正确，确保使用的是正确的 Shader

---

## 完成检查清单

- [ ] 创建了两个材质（VertexLit 和 PixelLit）
- [ ] 创建了两个球体并分别应用材质
- [ ] 配置了 LambertCompareController 脚本
- [ ] 观察了逐顶点与逐像素的视觉差异
- [ ] 旋转了平行光观察明暗变化
- [ ] 切换了漫反射颜色
- [ ] 填写了实验数据记录表
- [ ] 理解了两者的计算流程区别
