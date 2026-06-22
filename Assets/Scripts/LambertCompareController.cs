using UnityEngine;

public class LambertCompareController : MonoBehaviour
{
    [Header("需要切换 Shader 的物体")]
    public GameObject[] targetObjects;

    [Header("平行光（用于旋转）")]
    public Light directionalLight;

    [Header("材质")]
    public Material vertexLitMaterial;
    public Material pixelLitMaterial;

    [Header("灯光旋转速度（度/秒）")]
    public float lightRotationSpeed = 60f;  // 调高默认速度，方便观察

    private bool useVertexLit = false;
    private Color originalDiffuseColor;
    private int colorIndex = 0;  // 修复颜色循环bug

    void Start()
    {
        if (vertexLitMaterial != null)
        {
            originalDiffuseColor = vertexLitMaterial.GetColor("_Diffuse");
        }

        UpdateMaterials();
    }

    void Update()
    {
        // 切换渲染模式：按 C 键
        if (Input.GetKeyDown(KeyCode.C))
        {
            useVertexLit = !useVertexLit;
            UpdateMaterials();
            Debug.Log("当前模式: " + (useVertexLit ? "逐顶点" : "逐像素"));
        }

        // 旋转平行光：按住 A / ← 或 D / →
        if (Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A))
        {
            RotateLight(-1);
        }
        if (Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D))
        {
            RotateLight(1);
        }

        // 按 Q 切换漫反射颜色
        if (Input.GetKeyDown(KeyCode.Q))
        {
            ToggleDiffuseColor();
        }
    }

    void UpdateMaterials()
    {
        Material targetMaterial = useVertexLit ? vertexLitMaterial : pixelLitMaterial;

        foreach (GameObject obj in targetObjects)
        {
            if (obj != null)
            {
                Renderer renderer = obj.GetComponent<Renderer>();
                if (renderer != null)
                {
                    renderer.material = targetMaterial;
                }
            }
        }
    }

    void RotateLight(float direction)
    {
        if (directionalLight != null)
        {
            directionalLight.transform.Rotate(Vector3.up, direction * lightRotationSpeed * Time.deltaTime, Space.World);
        }
    }

    void ToggleDiffuseColor()
    {
        // 定义颜色循环列表
        Color[] colors = {
            originalDiffuseColor,
            Color.red,
            Color.green,
            Color.blue,
            Color.yellow,
            Color.cyan,
            Color.magenta
        };

        // 切换到下一个颜色
        colorIndex = (colorIndex + 1) % colors.Length;
        Color newColor = colors[colorIndex];

        if (vertexLitMaterial != null)
        {
            vertexLitMaterial.SetColor("_Diffuse", newColor);
        }
        if (pixelLitMaterial != null)
        {
            pixelLitMaterial.SetColor("_Diffuse", newColor);
        }

        Debug.Log("漫反射颜色已切换为: " + newColor);
    }

    void OnGUI()
    {
        // 面板显示在右上角
        int boxWidth = 320;
        int boxHeight = 220;
        int margin = 10;

        float boxX = Screen.width - boxWidth - margin;
        float boxY = margin;

        GUI.Box(new Rect(boxX, boxY, boxWidth, boxHeight), "Lambert 漫反射对比实验");

        GUILayout.BeginArea(new Rect(boxX + 10, boxY + 25, boxWidth - 20, boxHeight - 35));

        GUILayout.Label("<b>当前模式:</b> " + (useVertexLit ? "逐顶点 (Vertex Lit)" : "逐像素 (Pixel Lit)"));
        GUILayout.Space(5);
        GUILayout.Label("<color=" + (useVertexLit ? "yellow" : "cyan") + ">" +
                        (useVertexLit ? "性能好，但精度低" : "精度高，但性能消耗大") +
                        "</color>");
        GUILayout.Space(10);

        GUILayout.Label("<b>操作按键:</b>");
        GUILayout.Label("[C] - 切换渲染模式");
        GUILayout.Label("[← / A] - 向左旋转平行光");
        GUILayout.Label("[→ / D] - 向右旋转平行光");
        GUILayout.Label("[Q] - 切换漫反射颜色");
        GUILayout.Space(10);

        if (GUILayout.Button("同时显示两种模式 (需双物体)"))
        {
            Debug.Log("请确保场景中有两个相同的物体，分别应用不同材质");
        }

        GUILayout.EndArea();
    }
}