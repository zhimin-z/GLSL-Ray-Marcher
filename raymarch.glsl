// Starter code from iq's Raymarching Primitives
// https://www.shadertoy.com/view/Xds3zN
// reference iq-terrain, iq-primitives
#define EPSILON 0.00001
#define MinStep 0.01
#define MaxDis 120.0
#define R 0.25
#define cpt vec3(0.0,R,0.0)
#define disi 1.2

//#define debugView1
//#define debugView2
//#define naive
#define terrMap
float iterate_num=0.0;
float terrain_y=0.0;
float sdPlane( vec3 p )
{
	return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
float length2( vec2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

float length8( vec2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}
float sdWheel( vec3 p, vec2 t )
{
  vec2 q = vec2(length2(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}


float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}
float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}
float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}


//----------------------------------------------------------------------

vec2 opS( vec2 d1, vec2 d2 )
{
   return (d1.x< -d2.x)?-d2:d1;
}

vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}


vec3 opTrans( vec3 p, vec3 s,vec3 r,vec3 t )//m:tranformation matrxi,s scale parameter
{
    
     mat4 S_inv = mat4(vec4(1.0/s.x,0,0,0),
                       vec4(0,1.0/s.y,0,0),
                       vec4(0,0,1.0/s.z,0),
                       vec4(0,0,0,1));
    
     mat4 T_inv = mat4(vec4(1,0,0,0),
                       vec4(0,1,0,0),
                       vec4(0,0,1,0),
                       vec4(vec3(-t),1));
    float sx = sin(r.x);
    float sy = sin(r.y);
    float sz = sin(r.z);
    
    float cx = cos(r.x);
    float cy = cos(r.y);
    float cz = cos(r.z);
  
   
    mat4 Rmatrix = mat4(	cy*cz,	cx*sz+cz*sx*sy,	sx*sz-cx*cz*sy,	0,
                      	   -cy*sz,	cx*cz-sx*sy*sz,	cz*sx+cx*sy*sz,	0,
                        	sy,		-cy*sx,			cx*cy,			0,
                        	0,		0,				0,				1);
    mat4 R_inv = mat4(	cy*cz,	        -cy*sz,	         sy,    0,
                     	cx*sz+cz*sx*sy,	cx*cz-sx*sy*sz, -cy*sx, 0,
                     	sx*sz-cx*cz*sy, cz*sx+cx*sy*sz,  cx*cy, 0,	
                     	0,0,0,1);

    
    mat4 invertMatrix = S_inv*R_inv*T_inv;
    
    vec4 p_transformed = invertMatrix*vec4(p,1.0);
   
    return p_transformed.xyz;

}
//----------------------------------------------------------------------


float Textyrek( vec3 point )
{
    
	float k = 1.0-smoothstep( 0.42, 0.95, texture2D( iChannel0, 0.04*point.xz,-70.0).x);
	return  k*texture2D( iChannel1, 0.02*point.zx ).x;

}

float mapTerrain( in vec3 pos )
{
	return pos.y - Textyrek(pos);
}

vec2 setGeo( in vec3 point )
{
    //plane,box,rounded box,shpere,wheel,cylinder
    //sphere:0,0,0,R=0.25
    
    vec2 res = opU(vec2( sdPlane(point), 1.0 ), vec2( sdSphere(point-cpt, R ), 50.0 ) );
#ifdef terrMap
    float tt=0.5;
    
    res = opU(vec2( mapTerrain(point), 1.0 ), vec2( sdSphere(point-cpt-0.5, R ), 50.0 ) );
#else 
    float tt=0.0;
    res = opU(res, vec2(  sdBox  (point-vec3(cpt.x+disi,cpt.y, cpt.z)-tt, vec3(R) ),21.0 ) );
 #endif 
    res = opU( res, vec2( udRoundBox(point-vec3( cpt.x-disi,cpt.y, cpt.z)-tt, vec3(R-0.1), 0.1 ), 41.0 ) );
	res = opU( res, vec2( sdTorus   (point-vec3( cpt.x-2.0*disi,cpt.y,cpt.z)-tt, vec2(R,0.05) ), 25.0 ) );
    res = opU( res, vec2( sdWheel   (point-vec3( cpt.x+2.0*disi,cpt.y,cpt.z)-tt, vec2(R,0.05) ), 35.0 ) );    
#ifdef terrMap
#else 
    res = opU( res, vec2( sdBox   (point-vec3(cpt.x+disi, cpt.y, cpt.z+disi)-tt, vec3(R/3.0) ),60.0 ));
    res = opU( res, vec2( sdCone  (point-vec3(cpt.x+disi, cpt.y+0.1, cpt.z-disi)-tt, vec3(R) ),31.0 ) );

    //operation:subtraction,repeat, transform
    res = opS( res, vec2( sdSphere (point-vec3(cpt.x+disi,cpt.y, cpt.z)-tt,R+0.05 ), 0.0 ));
    //repeatl;
    vec3 p1 = opRep(point-vec3(cpt.x+disi, cpt.y, cpt.z+disi), vec3(2.0) );
    res = opU(res,vec2( sdBox (p1, vec3(R/3.0) ),10.0 ) );
   //transform
    vec3 sm=vec3(12.5,1.5,1.0);
    vec3 rm=vec3(45.0,0.0,0.0);
    vec3 tm=vec3(0.0,0.0,0.8);
    vec3 p2 = opTrans(point-vec3(cpt.x, cpt.y, cpt.z+disi)-tt,sm,rm,tm);
    res = opU(res, vec2( sdCylinder (p2, vec2(R/2.0,R/2.0) ), 15.0 ) );

#endif
    return res;
}


vec2 acc_rayMarching(vec3 dir, vec3 ori)
{
    
    vec3 point;
    vec2 h;
    float t=1.0;
    float m=0.0;
    for(float s=0.0;s<MaxDis;s+=MinStep)
	{
        point = ori+t*dir;
       //***********************//
        h= setGeo(point);
        //*************************//
        if(h.x<EPSILON)
        {  
          break;
        }
        if(t>MaxDis)break;
        t+= max(h.x,MinStep);
        iterate_num++;
        m =h.y;
	}
     return vec2( t, m );
}
vec2 naive_rayMarching(vec3 dir, vec3 ori)
{
    vec3 point;
    vec2 dis;
    float m=0.0;
    float t_temp=0.0;
    for(float t=.0;t<MaxDis;t+=MinStep)
    {
          point=ori+dir*t;
          dis= setGeo(point);//length(point-centerPoint)-R;
         
       if(dis.x<.0){break;}
        m=dis.y;
        t_temp=t;
        iterate_num++;
    }
    return vec2(t_temp,m);
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float maxt,in float k )
{

    float t = mint;
	float res = 1.0;
    for ( float i = 0.0; i < MaxDis; i++ )
    {
        float h = setGeo( ro + rd * t ).x;
        if ( h < EPSILON ){return 0.0;break;}	
		res = min( res, k * h / t );
        t += h;
		if ( t > maxt )
			break;
    }
    return res;
}
vec3 calTerrNor()
{
return vec3(1.0,1.0,1.0);
}
vec3 diffNormal( in vec3 point )
{
	vec3 eps = vec3( EPSILON, 0.0, 0.0 );
	vec3 nor = vec3(
	    setGeo(point+eps.xyy).x - setGeo(point-eps.xyy).x,
	    setGeo(point+eps.yxy).x - setGeo(point-eps.yxy).x,
	    setGeo(point+eps.yyx).x - setGeo(point-eps.yyx).x );
	return normalize(nor);
}

float calAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    float d=0.0;
    for( int i=0; i<6; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * h + pos;
        d = setGeo(aopos).x;
        occ += -(d-h)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}


vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.8, 0.9, 1.0);
    //two method of ray marching:
#ifdef naive
    vec2 res = naive_rayMarching(rd,ro);
#else
    vec2 res = acc_rayMarching(rd,ro);
#endif
    
#ifdef debugView1
    //res = acc_rayMarching(rd,ro);
	float tv = res.x/25.0;
    col = vec3(tv);
	return vec3( clamp(col,0.0,1.0));
#else
#endif
    
#ifdef debugView2
   // res = acc_rayMarching(rd,ro);
    //res = naive_rayMarching(rd,ro);
    col=vec3(float(iterate_num/(2.0*MaxDis)));
    return vec3( clamp(col,0.0,1.0));
#else
#endif
    float t = res.x;
	float m = res.y;
    
    if( m>-0.5 )
    {
      
        vec3 point = ro + t*rd;
        vec3 normal = diffNormal( point );
        vec3 ref = reflect( rd, normal );
        vec3 lightpos=vec3(0.8, 0.6, -0.5);
        vec3 lightdir=lightpos-point;        
		col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.20)*(m-1.0) );

        if( m<2.0 )//m=1.0(plane)
        {
            
            float f = mod( floor(5.0*point.z) + floor(5.0*point.x), 2.0);
            col = 0.4 + 0.1*f*vec3(1.0);
        }
        // material  
        float occ = calAO( point, normal );
       //float occ=1.0;
		float amb = clamp( 0.5+0.5*normal.y, 0.0, 1.0 );
        float dif = clamp( dot( normal, lightdir ), 0.0, 1.0 );
        float dom = smoothstep( -0.1, 0.1, ref.y );
        
        float light_len=length(lightdir);
        vec3 H=normalize(lightdir+normalize(ro-point));
        float hdot=dot(H,normal);
        float spec = float(max(pow(hdot,10.0),0.0));
        float fre = pow( clamp(1.0+dot(normal,rd),0.0,1.0), 2.0 );
        float attn = 1.0 - pow( min( 1.0, length(lightdir) / 10.0 ), 2.0 );
        dif *= softshadow( point, lightpos, 0.02, 2.5,8.0 );
        dom *= softshadow( point, ref, 0.02, 2.5,8.0 );
        
		float phong_color =0.0;
        phong_color= 1.5*dif+1.3*spec+0.1*amb*occ;
        phong_color += 0.40*dom*occ;
        phong_color += 0.40*fre*occ;
		col = col*phong_color*attn;
#ifdef terrMap
        if(m<1.5){
            float f = mod( floor(5.0*point.z) + floor(5.0*point.x), 2.0);
            vec3 basec=vec3(0.75,0.75,0.75);
            col = basec;
            col*=1.0*dif+0.2*amb*occ;
            col.xyz = mix( col.xyz, basec, 0.2);
            col*=0.9;
            // col*=vec3(0.2,0.8,0.7);
            
        }
        //the terrin map
#else
#endif

    }

	return vec3( clamp(col,0.0,1.0) );

}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
	p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
		 
	float time = 15.0 + iGlobalTime;

	// camera	
	vec3 ro = vec3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 3.5*sin(0.1*time + 6.0*mo.x) );
	vec3 ta = vec3( -0.5, -0.4, 0.5 );
	
	// camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
	vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    // render	
    vec3 col = render( ro, rd );

	col = pow( col, vec3(0.4545) );

    fragColor=vec4( col, 1.0 );
}
