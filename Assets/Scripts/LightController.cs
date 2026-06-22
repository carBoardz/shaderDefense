using UnityEngine;
using System.Collections.Generic;

public class LightController : MonoBehaviour
{
    [Header("所有光源列表")]
    public Light[] allLights;

    private Dictionary<string, bool> lightStates = new Dictionary<string, bool>();
    private LightRenderMode currentRenderMode = LightRenderMode.Auto;

    void Start()
    {
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
        // 切换光源开关：按 F1 ~ F4
        if (Input.GetKeyDown(KeyCode.F1)) ToggleLight(0);
        if (Input.GetKeyDown(KeyCode.F2)) ToggleLight(1);
        if (Input.GetKeyDown(KeyCode.F3)) ToggleLight(2);
        if (Input.GetKeyDown(KeyCode.F4)) ToggleLight(3);

        // 切换渲染模式：按 M 键
        if (Input.GetKeyDown(KeyCode.M))
        {
            SwitchRenderMode();
        }

        // 重置所有光源：按 R 键
        if (Input.GetKeyDown(KeyCode.R))
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
        // 面板显示在右下角
        int boxWidth = 300;
        int boxHeight = 180;
        int margin = 10;

        float boxX = Screen.width - boxWidth - margin;
        float boxY = Screen.height - boxHeight - margin;

        GUI.Box(new Rect(boxX, boxY, boxWidth, boxHeight), "光源控制面板");

        GUILayout.BeginArea(new Rect(boxX + 10, boxY + 25, boxWidth - 20, boxHeight - 35));
        GUILayout.Label($"当前渲染模式: {currentRenderMode}");
        GUILayout.Space(5);

        // 显示每个光源的状态（带动态复选框）
        for (int i = 0; i < allLights.Length; i++)
        {
            if (allLights[i] != null)
            {
                bool isOn = GUI.Toggle(
                    new Rect(0, 25 + i * 25, 100, 20),
                    allLights[i].enabled,
                    $"[F{i + 1}]"
                );

                GUI.Label(
                    new Rect(100, 25 + i * 25, 180, 20),
                    $"{allLights[i].name} ({allLights[i].type})"
                );

                if (isOn != allLights[i].enabled)
                {
                    allLights[i].enabled = isOn;
                    lightStates[allLights[i].name] = isOn;
                }
            }
        }

        GUILayout.Space(5);
        GUILayout.Label("按 [F1-F4] 切换光源开关");
        GUILayout.Label("按 [M] 切换渲染模式");
        GUILayout.Label("按 [R] 重置所有光源");

        GUILayout.EndArea();
    }
}