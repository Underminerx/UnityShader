using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveObject : MonoBehaviour
{
    [Range(0f, 10f)]
    public float speed = 3.0f;
    void Update()
    {
        this.transform.Translate(-speed * Time.deltaTime, 0.0f, 0.0f);    
    }
}
