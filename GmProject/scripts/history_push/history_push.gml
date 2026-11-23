/// history_push()
/// @desc Reserves a new slot at the beginning of the history list.

function history_push()
{
	var maxhist = max(10, setting_history_limit);
	if (history_amount >= maxhist)
	{
		for (var d = maxhist - 1; d < history_amount; d++)
			with (history[d])
				instance_destroy()
		history_amount = maxhist - 1
	}
	
	history_amount++
	for (var h = history_amount; h > 0; h--)
		history[h] = history[h - 1]
}
