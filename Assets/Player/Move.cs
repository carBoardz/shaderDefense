using UnityEngine;

public class Move : MonoBehaviour
{
    [Header("移动设置")]
    public float moveSpeed = 5f;
    public float turnSmoothTime = 0.1f;
    public float jumpHeight = 1.5f;
    public float gravity = -9.81f;

    [Header("相机设置")]
    public Transform cameraTransform;
    public float cameraDistance = 5f;
    public float cameraHeight = 2f;
    public float mouseSensitivity = 2f;
    public float minVerticalAngle = -30f;
    public float maxVerticalAngle = 60f;

    private CharacterController controller;
    private float turnSmoothVelocity;
    private Vector3 velocity;

    private float currentHorizontalAngle = 0f;
    private float currentVerticalAngle = 10f;

    void Start()
    {
        controller = GetComponent<CharacterController>();

        // ---------- 锁定并隐藏光标 ----------
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;

        if (cameraTransform == null)
        {
            Camera cam = Camera.main;
            if (cam != null) cameraTransform = cam.transform;
            else Debug.LogError("未找到 MainCamera，请手动拖入 cameraTransform！");
        }
        currentHorizontalAngle = 0f;
    }

    void Update()
    {
        // ---------- 鼠标控制相机旋转 ----------
        float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity;
        float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity;

        currentHorizontalAngle += mouseX;
        currentVerticalAngle -= mouseY;
        currentVerticalAngle = Mathf.Clamp(currentVerticalAngle, minVerticalAngle, maxVerticalAngle);

        // ---------- ESC 释放光标 ----------
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }

        // ---------- 点击游戏窗口时重新锁定（可选） ----------
        if (Input.GetMouseButtonDown(0) && Cursor.lockState == CursorLockMode.None)
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }
    }

    void FixedUpdate()
    {
        // ---------- 相机跟随 ----------
        Vector3 offset = new Vector3(0, cameraHeight, -cameraDistance);
        Quaternion rotation = Quaternion.Euler(currentVerticalAngle, currentHorizontalAngle, 0);
        Vector3 targetPosition = transform.position + rotation * offset;
        cameraTransform.position = Vector3.Lerp(cameraTransform.position, targetPosition, Time.deltaTime * 10f);
        cameraTransform.LookAt(transform.position + Vector3.up * 1.5f);

        // ---------- 玩家移动 ----------
        float horizontal = Input.GetAxisRaw("Horizontal");
        float vertical = Input.GetAxisRaw("Vertical");
        Vector3 inputDir = new Vector3(horizontal, 0, vertical).normalized;

        if (inputDir.magnitude >= 0.1f)
        {
            Vector3 forward = cameraTransform.forward;
            forward.y = 0;
            forward.Normalize();
            Vector3 right = cameraTransform.right;
            right.y = 0;
            right.Normalize();

            Vector3 moveDir = forward * vertical + right * horizontal;
            moveDir.Normalize();

            controller.Move(moveDir * moveSpeed * Time.deltaTime);

            float targetAngle = Mathf.Atan2(moveDir.x, moveDir.z) * Mathf.Rad2Deg;
            float angle = Mathf.SmoothDampAngle(transform.eulerAngles.y, targetAngle, ref turnSmoothVelocity, turnSmoothTime);
            transform.rotation = Quaternion.Euler(0, angle, 0);
        }

        // ---------- 跳跃与重力 ----------
        if (controller.isGrounded && velocity.y < 0)
            velocity.y = -2f;

        if (Input.GetButtonDown("Jump") && controller.isGrounded)
        {
            velocity.y = Mathf.Sqrt(jumpHeight * -2f * gravity);
        }

        velocity.y += gravity * Time.deltaTime;
        controller.Move(velocity * Time.deltaTime);
    }

    // ---------- 窗口失焦时自动恢复光标（可选） ----------
    void OnApplicationFocus(bool hasFocus)
    {
        if (!hasFocus)
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
        else
        {
            // 如果重新获得焦点，但处于游戏运行状态，可以重新锁定（根据需求）
            // 这里为了防止误触，不自动锁定，让玩家点击鼠标时再锁定
        }
    }
}