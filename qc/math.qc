


float SoundRadius(float radius)
{
	return (800 / radius);
//	return ((cvar("snd_soundradius") / 1.5) / radius);
}

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

vector AngleDifference(vector from, vector to)
{
	vector d = to - from;

	if (d_x > 180) d_x -= 360;
	if (d_x < -180) d_x += 360;

	if (d_y > 180) d_y -= 360;
	if (d_y < -180) d_y += 360;

	if (d_z > 180) d_z -= 360;
	if (d_z < -180) d_z += 360;

	return d;
}
	
vector(vector angle) NormalizeAngle =
{
	while (angle_x < -180) angle_x += 360;
	while (angle_x > 180) angle_x -= 360;

	while (angle_y < -180) angle_y += 360;
	while (angle_y > 180) angle_y -= 360;

	while (angle_z < -180) angle_z += 360;
	while (angle_z > 180) angle_z -= 360;

	return angle;
}

vector(vector angle) ClampAngle =
{
	while (angle_y > 180) angle_y -= 360;
	while (angle_y < -180) angle_y += 360;

	if (angle_x > 89.0) angle_x = 89.0;
	if (angle_x < -89.0) angle_x = -89.0;

	angle_z = 0;

	return angle;
}

float Lerp(float a, float b, float factor)
{
    return a * (1.0 - factor) + (b * factor);
}

vector LerpVector(vector a, vector b, float factor)
{
    return a * (1.0 - factor) + (b * factor);
}

float LerpAngle(float start, float end, float t) 
{
    float difference = mod(end - start + 360.0, 360.0); // Wrap difference to [0, 360)
    if (difference > 180.0) difference -= 360.0;        // Shortest path
    return mod(start + difference * t + 360.0, 360.0); // Lerp and wrap result to [0, 360)
}

vector LerpAngles(vector start, vector end, float t) 
{
	vector result;
    result_x = LerpAngle(start_x, end_x, t);
    result_y = LerpAngle(start_y, end_y, t);
    result_z = LerpAngle(start_z, end_z, t);
    return result;
}

float RandomInt(float minf, float maxf)
{
	float r = rint(random(minf - 0.5, maxf + 0.5));
	if(r <= minf) r = minf; //if we dont do this sometimes ftos will return "-0"
	if(r >= maxf) r = maxf;
	return r;
	//return rint(random(minf - 0.5, maxf + 0.5));
}

vector GetCenter(entity e)
{
	return (e.absmin + e.absmax) * 0.5;
}

vector Math_GetCenterOffset(entity e)
{
    return (e.mins + e.maxs) * 0.5;
};

float vdot (vector v1, vector v2)
{
	return v1_x * v2_x + v1_y * v2_y + v1_z * v2_z;
}