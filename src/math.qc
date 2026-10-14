
const float M_PI = 3.14159265358979323846;

float VectorAbsSum(vector v) 
{
    return fabs(v_x) + fabs(v_y) + fabs(v_z);
}

vector BetterNormalize(vector v)
{
	float absSum = VectorAbsSum(v);
	if(absSum == 0) return v;
	return v / absSum;
}

#define Math_AngleDelta Math_AngleDistance
float Math_AngleDistance(float next, float cur)
{
	float delta = next - cur;
	while (delta > 180) delta = delta - 360;
    while (delta < -180) delta = delta + 360;
	return delta;
}
vector Math_AnglesDifference(vector from, vector to)
{
	vector d = to - from;

	while (d_x > 180) d_x -= 360;
	while (d_x < -180) d_x += 360;

	while (d_y > 180) d_y -= 360;
	while (d_y < -180) d_y += 360;

	while (d_z > 180) d_z -= 360;
	while (d_z < -180) d_z += 360;

	return d;
}
	
vector Math_NormalizeAngle(vector angle)
{
	while (angle_x < -180) angle_x += 360;
	while (angle_x > 180) angle_x -= 360;

	while (angle_y < -180) angle_y += 360;
	while (angle_y > 180) angle_y -= 360;

	while (angle_z < -180) angle_z += 360;
	while (angle_z > 180) angle_z -= 360;

	return angle;
}

vector Math_ClampAngle(vector angle)
{
	while (angle_y > 180) angle_y -= 360;
	while (angle_y < -180) angle_y += 360;

	if (angle_x > 89.0) angle_x = 89.0;
	if (angle_x < -89.0) angle_x = -89.0;

	angle_z = 0;

	return angle;
}

float Math_AngleMod(float a)
{
    while (a < 0)   a += 360;
    while (a >= 360) a -= 360;
    return a;
}

float Math_ApproachAngle(float t, float value, float speed)
{
	t = Math_AngleMod(t);
	value = Math_AngleMod(t); //not a bug, strange
	float delta = t - value;

	if (speed < 0) speed = -speed;
	if (delta < -180) delta += 360;
	else if (delta > 180) delta -= 360;

	if (delta > speed) value += speed;
	else if (delta < -speed) value -= speed;
	else  value = t;

	return value;
}

float Math_Approach(float goal, float val, float speed)
{
	float delta = goal - val;
	if (delta > speed)       val = val + speed;
	else if (delta < -speed) val = val - speed;
	else                     val = goal;
	return val;
}

// Engine stores angles wrapped to [0,360]. Steering/lean math needs signed [-180,180]
float Math_SignedAngle(float a)
{
	a = Math_AngleMod(a);
	if (a > 180) a = a - 360;
	return a;
}

float Math_DotProduct(vector a, vector b)
{ 
	return(a_x * b_x + a_y * b_y + a_z * b_z); 
}

float Math_Lerp(float a, float b, float factor)
{
    return a * (1.0 - factor) + (b * factor);
}

vector Math_LerpVector(vector a, vector b, float factor)
{
    return a * (1.0 - factor) + (b * factor);
}

float Math_LerpAngle(float start, float end, float t) 
{
    float difference = mod(end - start + 360.0, 360.0); // Wrap difference to [0, 360]
    if (difference > 180.0) difference -= 360.0;        // Shortest path
    return mod(start + difference * t + 360.0, 360.0);  // Lerp and wrap result to [0, 360]
}

vector Math_LerpAngles(vector start, vector end, float t) 
{
	vector result;
    result_x = Math_LerpAngle(start_x, end_x, t);
    result_y = Math_LerpAngle(start_y, end_y, t);
    result_z = Math_LerpAngle(start_z, end_z, t);
    return result;
}

float Math_RandomInt(float minf, float maxf)
{
	float r = rint(random(minf - 0.5, maxf + 0.5));
	if(r <= minf) r = minf; //if we dont do this sometimes ftos will return "-0"
	if(r >= maxf) r = maxf;
	return r;
}

vector GetCenter(entity e)
{
	return (e.absmin + e.absmax) * 0.5;
}

vector VecBModelOrigin(entity e)
{
	return e.absmin + (e.size * 0.5);
}

vector Math_GetCenterOffset(entity e)
{
    return (e.mins + e.maxs) * 0.5;
};

float Math_Dot(vector v1, vector v2)
{
	return v1_x * v2_x + v1_y * v2_y + v1_z * v2_z;
}

float Math_Fix(float angle)
{
	while (angle < 0) angle += 360;
	while (angle > 360) angle -= 360;
	return angle;
}

vector Math_FixupAngles(vector v)
{
	v_x = Math_Fix(v_x);
	v_y = Math_Fix(v_y);
	v_z = Math_Fix(v_z);
	return v;
}

float Math_Clamp(float x, float a, float b)
{
    if (x < a) return a;
    if (x > b) return b;
    return x;
}

// One step of a first order lowpass, per axis. Returns the new filter state and
// the caller assigns it back: QuakeC has no pointers, so the C original's
// in/out store parameter cannot be ported directly, and lowpass happens to
// return exactly what it stores. A highpass is then the caller writing
// `store = Math_Lowpass3(v, f, store); out = v - store;`.
//
// `frac` is the per-axis blend for THIS frame, already multiplied by frametime.
vector Math_Lowpass3(vector value, vector frac, vector store)
{
	frac_x = Math_Clamp(frac_x, 0, 1);
	frac_y = Math_Clamp(frac_y, 0, 1);
	frac_z = Math_Clamp(frac_z, 0, 1);
	return [store_x * (1 - frac_x) + value_x * frac_x,
	        store_y * (1 - frac_y) + value_y * frac_y,
	        store_z * (1 - frac_z) + value_z * frac_z];
}

// As above, then pinned to within `limit` of the input, so a long frame or a
// jump in the input cannot leave the state arbitrarily far behind. A zero limit
// pins the store to the input exactly, which makes the highpass output zero.
vector Math_Lowpass3Limited(vector value, vector frac, vector limit, vector store)
{
	store = Math_Lowpass3(value, frac, store);
	return [Math_Clamp(store_x, value_x - limit_x, value_x + limit_x),
	        Math_Clamp(store_y, value_y - limit_y, value_y + limit_y),
	        Math_Clamp(store_z, value_z - limit_z, value_z + limit_z)];
}

float Math_InFront(vector targ, float maxDot = 0.35)
{
	makevectors(self.angles);
	vector vec = normalize(targ - (self.origin + self.view_ofs));
	float dot = vec * v_forward;
	if(dot > maxDot) return TRUE;
	return FALSE;
};
