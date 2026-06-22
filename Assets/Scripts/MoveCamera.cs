using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveCamera : MonoBehaviour
{
    private Transform cameraTransform;
    private bool isAt15 = false;  // 记录当前是否在 Z=15 的位置

    private void Start()
    {
        cameraTransform = transform;
    }

    void Update()
    {
        // 使用 GetKeyDown 只在按键按下那一帧触发一次
        if (Input.GetKeyDown(KeyCode.M))
        {
            // 切换标志
            isAt15 = !isAt15;

            // 获取当前位置
            Vector3 newPos = cameraTransform.position;

            // 根据标志设置 Z 值
            newPos.z = isAt15 ? 15f : 0f;

            // 应用新位置
            cameraTransform.position = newPos;
        }
    }
}