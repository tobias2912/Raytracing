
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

	struct hit_record{
		float t;
		vec3 p;
		vec3 normal;
	}

	struct sphere{
		vec3 center;
		float radius;

		static sphere from(vec3 center, float radius){
			sphere s;
			s.center = center;
			s.radius = radius;
			return s;
		}

		bool intersect(ray r, float t_min, float t_max, hit_record rec){
			vec3 oc = r.origin - center;
			float a = dot(r.direction, r.direction);
			float b = dot(oc, r.direction);
			float c = dot(oc, oc) - radius*radius;
			float discriminant = b*b - a*c;
			if(discriminant>0){
				float temp = (-b - sqrt(b*b-a*c))/a;
				if (temp < t_max && temp> t_min){
					rec.t = temp;
					rec.p = r.point_at(rec.t);
					rec.normal = (rec.p - center)/radius;
					return true;
				}
				temp = (-b + sqrt(b*b-a*c))/a;
				if (temp < t_max && temp> t_min){
					rec.t = temp;
					rec.p = r.point_at(rec.t);
					rec.normal = (rec.p - center)/radius;
					return true;
				}
			}
			return false;
		}
	}
	

	float hit_sphere(vec3 center, float radius, ray r)
	{
		vec3 oc = r.origin - center;
		float a = dot(r.direction, r.direction);
		float b = 2.0 * dot(oc, r.direction);
		float c = dot(oc, oc) - radius*radius;
		float discriminant = b*b - 4*a*c;
		if (discriminant < 0) {
			return -1.0;
		} else {
			return (-b - sqrt(discriminant)) / (2.0*a);
		}
	}

	bool intersect_list(ray r, float t_min, float t_max, hit_record rec){
		hit_record temp_rec;
		bool hit_anything = false;
		double closest_so_far = t_max;
		for(int i=0; i<n_spheres; i++){

		}
	}

	vec3 color(ray r, list)
	{
		float t = hit_sphere(vec3(0,0,-1), 0.5, r);
		if (t > 0.0) {
			//hits sphere
			vec3 N = normalize(r.point_at(t) - vec3(0,0,-1));
			return 0.5*vec3(N.x+1, N.y+1, N.z+1);
		}
			
		vec3 unit_direction = normalize(r.direction);
		t = 0.5*(unit_direction.y + 1.0);
		//return (1.0-t)*vec3(1.0,1.0,1.0) + t*vec3(0.5,0.7,1.0);
		return lerp(vec3(1.0,1.0,1.0), vec3(0.5,0.7,1.0), t);
	}


	static const uint n_spheres = 2;
	//list of spheres
	static const 

	static const vec3 lower_left_corner = vec3(-2.0, -1.0, -1.0);
	static const vec3 horizontal = vec3(4.0, 0.0, 0.0);
	static const vec3 vertical = vec3(0.0, 2.0, 0.0);
	static const vec3 origin = vec3(0.0, 0.0, 0.0);

////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
    {
        float x = i.uv.x;
        float y = i.uv.y;

		ray r = ray::from(origin, lower_left_corner + x*horizontal + y*vertical);
		vec3 vec = color(r);

        col3 col = col3(vec[0], vec[1], vec[2]);

        return fixed4(col,1); 
    }	
////////////////////////////////////////////////////////////////////////////////////
	
	

ENDCG

}}}
