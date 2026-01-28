

#define SCRIPT_PLAYING 			0	// Playing the sequence
#define SCRIPT_WAIT 			1	// Waiting on everyone in the script to be ready
#define SCRIPT_CLEANUP 			2	// Cancelling the script / cleaning up
#define SCRIPT_WALK_TO_MARK 	3
#define SCRIPT_RUN_TO_MARK		4

.string TriggerTarget;
.float TriggerCondition;