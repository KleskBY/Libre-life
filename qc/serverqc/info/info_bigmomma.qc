

.float presequence;
.float reachdelay;
.string reachtarget;
.string reachsequence;

void info_bigmomma()
{
	self.scale = self.radius;
	self.speed =  self.reachdelay;
	self.message = self.reachtarget;
	self.netname = self.reachsequence;


}