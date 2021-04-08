
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
		int sph_index;
	};

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

	bool refract(vec3 v, vec3 n, float ni_over_nt, out vec3 refracted){
		vec3 uv = normalize(v);
		float dt = dot(uv,n);
		float discriminant = 1.0 - ni_over_nt*ni_over_nt*(1-dt*dt);
		if (discriminant > 0){
			refracted = ni_over_nt*(uv-n*dt) - n*sqrt(discriminant);
			return true;
		}
		else{
			return true;
		}


	}

	float schlick(float cosine, float refractive_index) {
		float r0 = (1.0 - refractive_index) / (1.0 + refractive_index);
		r0 = r0 * r0;
		return r0 + (1.0 - r0) * pow((1.0 - cosine), 5);
	}

	struct sphere{
		vec3 center;
		float radius;
		int materialType;
		vec3 albedo; 
		float fuzz; 
		float ref_idx;

		static sphere from(vec3 center, float radius, int materialType, vec3 albedo, float fuzz, float ref_idx){
			sphere s;
			s.center = center;
			s.radius = radius;
			s.materialType = materialType;
			s.albedo = albedo;
			s.fuzz = fuzz;
			s.ref_idx = ref_idx;
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
					rec.sph_index = 0;
					return true;
				}
				temp = (-b + sqrt(b*b-a*c))/a;
				if (temp < t_max && temp> t_min){
					rec.t = temp;
					rec.p = r.point_at(rec.t);
					rec.normal = (rec.p - center)/radius;
					rec.sph_index = 0;
					return true;
				}
			}
			return false;
		}

		bool scatter(ray r, hit_record rec, out vec3 attenuation, out ray scattered) {
			// 1 = metal, 0 = lambertian
			if (materialType == 1) {
				vec3 reflected = reflect(normalize(r.direction), rec.normal);
				scattered = ray::from(rec.p, reflected + fuzz*random_in_unit_sphere(r.direction));
				attenuation = albedo;
				return (dot(scattered.direction, rec.normal) > 0);
			
			}
			if(materialType == 2) {
				vec3 target = rec.p + rec.normal + random_in_unit_sphere(r.direction);
				scattered = ray::from(rec.p, target-rec.p); 
				attenuation = albedo; 
				return true; 
			}
			//Dielectrics
			if(materialType == 3){
				vec3 outward_normal;
				vec3 reflected = reflect(r.direction, rec.normal);
				float ni_over_nt;
				attenuation = vec3(1.0,1.0,1.0);
				vec3 refracted;
				float reflect_prob;
				float cosine;
				if (dot(r.direction, rec.normal) > 0){
					outward_normal = -rec.normal;
					ni_over_nt = ref_idx;
					cosine = ref_idx * dot(r.direction, rec.normal) /length(r.direction);
					//cosine = sqrt(1.0 - ref_idx * ref_idx * (1.0 - cosine * cosine));
				}else{
					outward_normal = rec.normal;
					ni_over_nt = 1.0 /ref_idx;
					cosine = -dot(r.direction, rec.normal) /length(r.direction);

				}
				if (refract(r.direction, outward_normal, ni_over_nt, refracted)){
					reflect_prob = schlick(cosine, ref_idx);
				}else{
					scattered = ray::from(rec.p, reflected); 
					reflect_prob = 1.0;
				}
				if (rand(r.direction)< reflect_prob){
					scattered = ray::from(rec.p, refracted);
				}
				return true;
			}
			return true;
		}
	};
	

	static const uint n_spheres = 5;

	//simulere en liste
	void getsphere(int i, out sphere sph)
	{
		if (i == 0) { sph.center = vec3( 0, 0, -1); sph.radius = 0.5; sph.materialType = 2; sph.albedo = vec3(0.1, 0.2, 0.5);sph.fuzz = 0.0; sph.ref_idx = 1.0; }
		if (i == 1) { sph.center = vec3( 0,-100.5, -1); sph.radius = 100; sph.materialType = 2; sph.albedo = vec3(0.8, 0.8, 0.0);sph.fuzz = 0.0; sph.ref_idx = 1.0;}
		if (i == 2) { sph.center = vec3( 1, 0, -1); sph.radius = 0.5; sph.materialType = 1; sph.albedo = vec3(0.8, 0.6, 0.2);sph.fuzz = 0.3; sph.ref_idx = 1.0;}
		if (i == 3) { sph.center = vec3( -1, 0, -1); sph.radius = 0.5; sph.materialType = 3; sph.albedo = vec3(0.0, 0.0, 0.0);sph.fuzz = 0.0; sph.ref_idx = 1.5;}
		if (i == 4) { sph.center = vec3( -1, 0, -1); sph.radius = -0.45; sph.materialType = 3; sph.albedo = vec3(0.0, 0.0, 0.0);sph.fuzz = 0.0; sph.ref_idx = 1.5;}
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
				temp_rec.sph_index = i;
				rec = temp_rec;
			}
		}
		return hit_anything;
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

		ray scattered;
		vec3 attenuation;

		while (foundhit && (maxC>0)){
			maxC--;
			sphere sph;
			getsphere(rec.sph_index, sph);
			sph.scatter(r, rec, attenuation, scattered);
			r = scattered;
			accumCol = 0.5*accumCol;
			foundhit = intersect_list(r, 0.001, 1000000000.0, rec);
		}

		if (foundhit && maxC == 0){

			return col3(0,0,0);
		} else {
			return accumCol*background(r);
		}
		
	}



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
