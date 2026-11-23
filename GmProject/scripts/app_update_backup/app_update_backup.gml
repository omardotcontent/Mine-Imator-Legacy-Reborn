/// app_update_backup()

function app_update_backup()
{
	if (window_busy = "" && project_folder != "" && (setting_backup || setting_autosave) && backup_next && current_time > backup_next)
	{
		backup_text_ani += 0.04 * delta
		
		if (backup_text_ani > 1)
		{
			if (setting_backup)
				project_backup()
			if (setting_autosave && project_changed && project_file != "")
			{
				project_save()
				toast_new(e_toast.INFO, text_get("projectautosaved"))
			}
			else if (!setting_backup)
				project_reset_backup()
			backup_text_ani = 4
		}
	}
	else
		backup_text_ani -= 0.04 * delta
	
	backup_text_ani = clamp(backup_text_ani, 0, 4)
}
