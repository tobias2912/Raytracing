
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

	static const vec3 lower_left_corner = vec3(-2.0, -1.0, -1.0);
	static const vec3 horizontal = vec3(4.0, 0.0, 0.0);
	static const vec3 vertical = vec3(0.0, 2.0, 0.0);
	static const vec3 origin = vec3(0.0, 0.0, 0.0);
	
	static const uint n_spheres = 2;
	
	

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
	struct camera
	{
		vec3 origin;
		vec3 lower_left_corner;
		vec3 horizontal;
		vec3 vertical;

		ray get_ray(float x, float y) {
			return ray::from(origin, lower_left_corner + x*horizontal + y*vertical);
		}

		static camera create_camera(){
			camera c;
			c.origin = vec3(0.0, 0.0, 0.0);
			c.lower_left_corner = vec3(-2.0, -1.0, -1.0);
			c.horizontal = vec3(4.0, 0.0, 0.0);
			c.vertical = vec3(0.0, 2.0, 0.0);
			return c;
		}

	};

	struct hit_record{
		float t;
		vec3 p;
		vec3 normal;
	};

	struct sphere{
		vec3 center;
		float radius;

		static sphere from(vec3 center, float radius){
			sphere s;
			s.center = center;
			s.radius = radius;
			return s;
		}

		//sphere::hit
		bool intersect(ray r, float t_min, float t_max, out hit_record rec){
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
	};
	
	//simulere en liste
	void getsphere(int i, out sphere sph)
	{
		if (i == 0) { sph.center = vec3( 0, 0, -1); sph.radius = 0.5;  }
		if (i == 1) { sph.center = vec3( 0,-100.5, -1); sph.radius = 100;  }
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
	//hitable_list
	bool intersect_list(ray r, float t_min, float t_max, out hit_record rec){
		hit_record temp_rec;
		bool hit_anything = false;
		float closest_so_far = t_max;
		for(int i=0; i<n_spheres; i++){
			sphere sph;
			getsphere(i, sph);
			if(sph.intersect(r, t_min, closest_so_far, temp_rec)){
				hit_anything = true;
				closest_so_far = temp_rec.t;
				rec = temp_rec;
			}
		}
		return hit_anything;
	}
	float rand(in float2 uv){
		float2 noise = (frac(sin(dot(uv, float2(12.9898, 78.233)*2.0)) * 43758.5453));
		return abs(noise.x + noise.y) * 0.5;
	}

	//get a random point inside a  sphere
	vec3 random_in_unit_sphere(vec3 direction) {
		vec3 p;
		float r =dot(direction, direction);
		do {
			r +=2.5;
			p = 2.0*vec3(rand(r+0.1), rand(r+0.2), rand(r+0.3)) - vec3(1.0,1.0,1.0);
		}while (dot(p,p) >= 1.0);
		return p;
	}
	vec3 background(ray r) {
		float t = 0.5 * (normalize(r.direction).y + 1.0);
		return lerp(vec3(1.0, 1.0, 1.0), vec3(0.5, 0.7, 1.0), t);
	}


	col3 color(ray r){
		hit_record rec;
		vec3 accumCol = {1,1,1};

		bool foundhit = intersect_list(r, 0.001, 1000000000.0, rec);
		int maxC = 7;
		while (foundhit && (maxC>0)){
			maxC--;
			vec3 raddir = random_in_unit_sphere(r.direction);
			r = ray::from(rec.p, raddir);
			accumCol = 0.5*accumCol;
			foundhit = intersect_list(r, 0.001, 1000000000.0, rec);
		}

		if (foundhit && maxC == 0){
			return col3(0,0,0);
		} else {
			return accumCol*background(r);
		}
		
	}

	// vec3 color(ray r){
	// 	hit_record rec;
	// 	if (intersect_list(r, 0.0, 1000000000.0, rec)){
	// 		vec3 target = rec.p + rec.normal + random_in_unit_sphere();
	// 		return 0.5*color(ray(rec.p, target - rec.p))
	// 	}
	// 	else{
	// 		vec3 unit_direction = normalize(r.direction);
	// 		float t = 0.5*(unit_direction.y+1);
	// 		return (1.0-t)*vec3(1.0,1.0,1.0) + t*vec3(0.5,0.5,1.0);
	// 	}
	// }

	

////////////////////////////////////////////////////////////////////////////////////////////////////////
	fixed4 frag(v2f i) : SV_Target
    {
		camera cam = camera::create_camera();
		int ns = 100;
		vec3 vec = vec3(0.0, 0.0, 0.0);
		for (int s=0; s < ns; s++) {
			float x = i.uv.x + rand(s) / 200.0;
			float y = i.uv.y + rand(s) / 100.0;
			
			ray r = cam.get_ray(x, y);
			vec3 p = r.point_at(2.0);
			vec += color(r);
		}
		vec /= float(ns);
        col3 col = col3(sqrt(vec[0]), sqrt(vec[1]), sqrt(vec[2]));

        return fixed4(col,1); 
    }	
////////////////////////////////////////////////////////////////////////////////////
	
	

ENDCG

}}}
