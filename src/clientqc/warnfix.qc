
void FixWarning()
{
	vector v1;
	v1 = view_angles;
	v1 = view_punchvector;
	v1 = getlight_dir;
	v1 = getlight_ambient;
	v1 = getlight_diffuse;
	v1 = particles_colormin;
	v1 = particles_colormax;
	v1 = [transparent_offset];
	v1 = [trace_dpstartcontents];
	v1 = [trace_dphitcontents];
	v1 = [trace_dphitq3surfaceflags];
	v1 = [stof(trace_dphittexturename)];
	v1 = [particles_alphamin];
	v1 = [particles_alphamax];
	v1 = [particles_fade];
	v1 = [trace_networkentity];
	v1 = [gettaginfo_parent];
	v1 = [stof(gettaginfo_name)];
	v1 = gettaginfo_offset;
	v1 = gettaginfo_forward;
	v1 = gettaginfo_right;
	v1 = gettaginfo_up;
	v1 = [useType];
	v1 = [useValue];
	v1 = [skill];
	v1 = [gameover];
	v1 = [stof(__fullspawndata)];
	v1 = activator.origin;
	v1 = damage_attacker.origin;
	v1 = [movedist];
	v1 = view_punchangle;
	v1 = [intermission_running];
	v1 = [intermission_exittime];
}