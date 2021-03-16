
// Fra https://docs.unity3d.com/Manual/SL-VertexFragmentShaderExamples.html
//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509640(v=vs.85).aspx
//https://msdn.microsoft.com/en-us/library/windows/desktop/ff471421(v=vs.85).aspx
// rand num generator http://gamedev.stackexchange.com/questions/32681/random-number-hlsl
// http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
// https://docs.unity3d.com/Manual/RenderDocIntegration.html
// https://docs.unity3d.com/Manual/SL-ShaderPrograms.html

Shader "Unlit/SingleColor"
{
		SubShader{ Pass	{
			
	CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		typedef vector <float, 3> vec3;  // to get more similar code to book
		typedef vector <fixed, 3> col3;
	
	struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};
	
	v2f vert(appdata v)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.uv;
		return o;
	}
	

	struct ray
	{
		vec3 origin;
		vec3 direction;

		static ray from(vec3 origin, vec3 direction) {
			ray r;
			r.origin = origin;
			r.direction = direction;

			return r;
		}

		vec3 point_at(float t) {
			return origin + t*direction;
		}
	};
	




	vec3 color(ray r)
	{
		vec3 unit_direction = normalize(r.direction);
		float t = 0.5*(unit_direction.y + 1.0);
		//return (1.0-t)*vec3(1.0,1.0,1.0) + t*vec3(0.5,0.7,1.0);
		return lerp(vec3(1.0,1.0,1.0), vec3(0.5,0.7,1.0), t);
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
    {
        float x = i.uv.x;
        float y = i.uv.y;

		vec3 lower_left_corner = vec3(-2.0, -1.0, -1.0);
		vec3 horizontal = vec3(4.0, 0.0, 0.0);
		vec3 vertical = vec3(0.0, 2.0, 0.0);
		vec3 origin = vec3(0.0, 0.0, 0.0);

		ray r = ray::from(origin, lower_left_corner + x*horizontal + y*vertical);
		vec3 vec = color(r);

        //col3 col = col3(vec[0], vec[1], vec[2]);

        return fixed4(vec,1); 
    }	
////////////////////////////////////////////////////////////////////////////////////
	
	

ENDCG

}}}
