/// menu_grid_settings()

function menu_grid_settings()
{
	draw_set_font(font_label)
	
	var draggerwid = max(210, text_max_width("viewgridrows", "viewgridcolumns") + 16 + dragger_width);
	dw = draggerwid
	
	tab_control_dragger()
	draw_dragger("viewgridcolumns", dx, dy, dragger_width, project_grid_columns, 0.05, 1, 10, 3, 1, tbx_grid_columns, action_project_grid_columns, null, true)
	tab_next()
	
	tab_control_dragger()
	draw_dragger("viewgridrows", dx, dy, dragger_width, project_grid_rows, 0.05, 1, 10, 3, 1, tbx_grid_rows, action_project_grid_rows, null, true)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewguidethirds", dx, dy, setting_view_guide_thirds, action_setting_view_guide_thirds)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewguidegolden", dx, dy, setting_view_guide_golden, action_setting_view_guide_golden)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewguidecrosshair", dx, dy, setting_view_guide_crosshair, action_setting_view_guide_crosshair)
	tab_next()
	
	tab_control_switch()
	draw_switch("viewguidesafearea", dx, dy, setting_view_guide_safe_area, action_setting_view_guide_safe_area)
	tab_next()
	
	settings_menu_w = (draggerwid + 24)
}
