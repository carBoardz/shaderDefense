using UnityEngine;

public class LightModeSwitcher : MonoBehaviour
{
    public Light[] lights;
    private int currentModeIndex = 0;
    private LightRenderMode[] modes = { LightRenderMode.Auto, LightRenderMode.ForcePixel, LightRenderMode.ForceVertex };
    private string[] modeNames = { "Auto", "ForcePixel", "ForceVertex" };

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            SwitchLightMode();
        }
    }

    void SwitchLightMode()
    {
        currentModeIndex = (currentModeIndex + 1) % modes.Length;
        LightRenderMode newMode = modes[currentModeIndex];
        
        foreach (Light light in lights)
        {
            if (light != null)
            {
                light.renderMode = newMode;
            }
        }
        
        Debug.Log("Light Render Mode switched to: " + modeNames[currentModeIndex]);
    }

    void OnGUI()
    {
        GUILayout.BeginArea(new Rect(10, 10, 300, 100));
        GUILayout.Label("Current Light Mode: " + modeNames[currentModeIndex]);
        GUILayout.Label("Press SPACE to switch mode");
        GUILayout.EndArea();
    }
}