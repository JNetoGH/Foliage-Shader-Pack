using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassShaderWind : MonoBehaviour
{
    Renderer rend;
    Material mat;

    void Start()
    {
        rend = GetComponent<Renderer>();
        mat = rend.material;
    }

    void Update()
    {
        // Atualiza o valor de _Time no material do shader
        float timeValue = Time.time; // ou outra lógica para controlar o tempo
        mat.SetFloat("_Time", timeValue);
    }
}
