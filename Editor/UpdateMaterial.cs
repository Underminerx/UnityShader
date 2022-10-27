using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(ProceduralTextureGeneration))]
public class UpdateMaterial : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();

        ProceduralTextureGeneration myScript = (ProceduralTextureGeneration)target;
        if (GUILayout.Button("���²���"))
        {
            myScript._UpdateMaterial();
        }
    }


}
