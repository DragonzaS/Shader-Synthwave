// Some settings here:

//// Enable Anti-Aliasing: a 2 means it calculates for variations per pixel
//// Comment it out to increase perfomance, but lower quality
#define AA 2

// for some randomized results
float hash13(vec3 p) {
    return fract(sin(dot(p, vec3(17.0, 59.4, 15.0))) * 43758.5453);
}


// Calculates all the infinitely expanding lines for both X and Y (in reality Z) lines
float infiniteZline ( vec3 p, vec3 c, float spacing) {
    p.yx -= c.yx;
    
    p.x = mod(p.x + 0.5 * spacing, spacing) / spacing * 0.5;
    
    return length(p.yx)-c.z;
}
float infiniteXline (vec3 p, vec3 c, float spacing) {
    p.yz -= c.yx;
    p.z = mod(p.z + 0.5 * spacing, spacing) / spacing * 0.5;
    return length(p.yz)-c.z;
}

// very simple gradient sun that is drawn from the center
vec3 drawSun( vec2 uv, vec3 orig_col) {
    float draw = smoothstep(0.,0.4,length(uv + vec2(0,-0.02)));
    vec3 col = mix(vec3(1.,2.,0.),orig_col, draw);
    
    return col;
}


// the box itself
float sdBox( vec3 p, vec3 b) {
  
  vec3 q = abs(p) - b;
  
  
  
  return length(max(q,0.01)) + min(max(q.x,max(q.y,q.z)),0.0);
}


float randomCubes (vec3 p, vec3 offset) {
    
    float spacing = 3.; //the spacing in between
    
    p.x = abs(p.x);
    
    float cell = floor((p.z + 0.5 * spacing) / spacing); //getting a "ID" of the box
    
    float randomness = hash13(vec3(cell, cell + 0.2, cell -0.2));
    
    //p = repeat(p, spacing);
    p.z = mod(p.z + 0.5 * spacing, spacing) - 0.5 * spacing;
    
    // "randomized" size of the cubes
    float scale = mix(0.6,1.4,randomness);
    

    return sdBox(p - offset, vec3(scale));
}


// contains all objects that are rendered, outputs the distance and the object type
vec2 map (vec3 p, vec3 camera) {
    //the ground plane
    float ground = p.y + 1.;
    // the grid lines
    float infZline = infiniteZline(p, vec3(0.,-1.,.01),1.);
    float infXline = infiniteXline(p, vec3(0, -1., .01), 1.);
    
    float final = min(infZline, ground);
    
    final = min(final, infXline);
    
    //float box = sdBox(repeat(p, 2.) - vec3(4. + sin(repeat(p,5.).z),-.5,1.), vec3(0.5, 0.5, 0.5));
    
    float box = randomCubes(p, vec3(8, -0.5,1.0));// creating infinite cubes with varied size
    float box2 = randomCubes(p, vec3(10, -0.5,0.0)); // second row to hide empty spaces in the first one
   
    
    final = min(final,box);
    final = min(final,box2);
    
    int closest = 0; //variable used to determine how to color the object
    if( 1. < 8.) {
        // detecting grid lines
        if(final == infZline && infZline < 2.) { closest = 2;};
        if(final == infXline && infXline < 2.) { closest = 2;};
        
    }
    if( final == box || final == box2) { closest = 3;};
    return vec2(final, closest);
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    #ifdef AA
    // runs the same render but each time slightly offset
    for(float x = 0.; x < 1.; x += 1./float(AA)) {
    for(float y = 0.; y < 1.; y += 1./float(AA)) {
    #else
    const float x = 0.,y = 0., AA = 1.;
    #endif

    vec2 uv = ((fragCoord + vec2(x,y)) * 2. - iResolution.xy) / iResolution.y;
    
    // ray origin and ray direction vectors; now we are moving the "Camera" not the enviroment
    vec3 ro = vec3(0,0,iTime);
    vec3 rd = normalize(vec3(uv, 1.));
    
    vec3 col = vec3(0.,0.3,0.6);
    
    // generating the horizon gradient, a lot of fine tuning was required
    float grad = smoothstep(-0.4,0.8, abs(uv.y));
    vec3 col_grad = mix(vec3(1.,0.1,0.4),vec3(0.5,0.1,0.6),grad - 0.08);
    col = col_grad;
    
    // draws the sun, changes the pixel color only when needed
    col = drawSun(uv, col);
    
    
    //the RAY MARCHING part
    
    float t = 0.;
    int i = 0;
    float close = 0.;
    float d = 0.;
    bool hit = true;
    //main for loop for each ray
    
    for(i = 0; i < 80; i++) {
        vec3 p = ro + rd * t;
        
        vec2 result = map(p, ro);
        d = result.x;
        close = result.y;
        
        t += d;
        
        if (d < 0.001) break;
        //if (t > 25. && close == 2.) {hit = false;break;};
        if (t > 33.) {hit = false;break;};
        
        // notify that nothing has been hit
    }
    
    if ( hit) {
        
        if( i < 60) { // mixing together the horizon and the ground to make it seem like a reflection
        
            vec3 col_ = min(vec3(float(i) / 80. + 0.1), vec3(0.8));
            col_ = col_ * vec3(1.,.0,.5);
            col_ = mix(col_,vec3(1.,0.1,0.4), float(i)/80. - 0.4);
            
            col = mix(col,col_, -uv.y/ 0.4);
        }
        // grid line detection
        if (close == 2.) { 
            col = mix(vec3(1),col_grad, 0.5);
        } else if (close == 3.) { // the CUBE
            col = mix(col, vec3(float(i)/100.),0.8);
            col = mix(col,col_grad,0.5);
            
        }
    }
    // adding color to final output, later used if AA enabled
    fragColor += vec4(col, 1);
    
    #ifdef AA
    }
    }
    // normalize the colors after anti-aliasing
    fragColor/=float(AA*AA);
    #endif
    
}
